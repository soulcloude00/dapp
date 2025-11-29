/**
 * Production Hydra Client for PropFi
 * Handles WebSocket connection to a Hydra Node with reconnection, trading, and UTxO management.
 */

class HydraClient {
    constructor(url = 'ws://localhost:4001') {
        this.url = url;
        this.ws = null;
        this.status = 'Disconnected';
        this.headId = null;
        this.snapshotNumber = 0;
        this.utxos = new Map();
        this.parties = [];
        this.callbacks = {};
        this.history = [];
        this.pendingTxs = new Map();
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 10;
        this.reconnectInterval = 5000;
        this.reconnectTimeout = null;

        // Trading stats
        this.stats = {
            totalTrades: 0,
            totalVolume: 0n,
            averageLatencyMs: 0,
            peakTps: 0,
            currentTps: 0
        };
        this.tpsWindow = [];
    }

    /**
     * Set a new URL for the Hydra node
     */
    setUrl(url) {
        this.url = url;
    }

    /**
     * Connect to the Hydra Node with reconnection support
     */
    connect() {
        return new Promise((resolve, reject) => {
            if (this.reconnectTimeout) {
                clearTimeout(this.reconnectTimeout);
                this.reconnectTimeout = null;
            }

            try {
                console.log(`🔌 Connecting to Hydra Node at ${this.url}...`);
                this.ws = new WebSocket(this.url);

                const connectionTimeout = setTimeout(() => {
                    reject(new Error('Connection timeout'));
                    this.ws?.close();
                }, 10000);

                this.ws.onopen = () => {
                    clearTimeout(connectionTimeout);
                    console.log('✅ Connected to Hydra Node');
                    this.reconnectAttempts = 0;
                    this.emit('connected', true);
                    this.emit('statusChanged', 'Connected');
                    // Notify Dart of connection
                    this._notifyDartConnectionChange(true);
                    resolve(true);
                };

                this.ws.onmessage = (event) => {
                    try {
                        const data = JSON.parse(event.data);
                        this.handleMessage(data);
                    } catch (e) {
                        console.error('Failed to parse Hydra message', e);
                    }
                };

                this.ws.onerror = (error) => {
                    console.error('Hydra WebSocket error', error);
                    this.emit('error', error);
                };

                this.ws.onclose = (event) => {
                    console.log(`❌ Disconnected from Hydra Node (code: ${event.code})`);
                    this.status = 'Disconnected';
                    this.emit('statusChanged', this.status);
                    this.emit('disconnected', event);
                    // Notify Dart of disconnection
                    this._notifyDartConnectionChange(false);
                    this.attemptReconnect();
                };
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     * Attempt reconnection with exponential backoff
     */
    attemptReconnect() {
        if (this.reconnectAttempts >= this.maxReconnectAttempts) {
            console.error('❌ Max reconnection attempts reached');
            this.emit('maxReconnectAttempts', true);
            return;
        }

        this.reconnectAttempts++;
        console.log(`🔄 Reconnecting (${this.reconnectAttempts}/${this.maxReconnectAttempts})...`);

        this.reconnectTimeout = setTimeout(() => {
            this.connect().catch(console.error);
        }, this.reconnectInterval * Math.min(this.reconnectAttempts, 3));
    }

    /**
     * Disconnect from the Hydra Node
     */
    disconnect() {
        if (this.reconnectTimeout) {
            clearTimeout(this.reconnectTimeout);
            this.reconnectTimeout = null;
        }
        if (this.ws) {
            this.ws.close(1000, 'Client disconnect');
            this.ws = null;
        }
        this.status = 'Disconnected';
    }

    /**
     * Handle incoming Hydra messages
     */
    handleMessage(data) {
        console.log(`📨 [${data.seq || '-'}] ${data.tag}`);
        this.history.push({ timestamp: Date.now(), ...data });

        // Keep history manageable
        if (this.history.length > 200) {
            this.history = this.history.slice(-100);
        }

        switch (data.tag) {
            case 'Greetings':
                this.handleGreetings(data);
                break;
            case 'HeadIsInitializing':
                this.status = 'Initializing';
                this.headId = data.headId;
                this.parties = data.parties || [];
                this.emit('statusChanged', this.status);
                this.emit('initializing', data);
                break;
            case 'Committed':
                this.emit('committed', data);
                break;
            case 'HeadIsOpen':
                this.status = 'Open';
                this.headId = data.headId;
                if (data.utxo) {
                    this.updateUtxos(data.utxo);
                }
                this.emit('statusChanged', this.status);
                this.emit('open', data);
                break;
            case 'SnapshotConfirmed':
                this.snapshotNumber = data.snapshot?.snapshotNumber || 0;
                if (data.snapshot?.utxo) {
                    this.updateUtxos(data.snapshot.utxo);
                }
                this.handleSnapshotConfirmed(data);
                this.emit('snapshotConfirmed', data);
                break;
            case 'TxValid':
                this.handleTxValid(data);
                this.emit('TxValid', data);
                break;
            case 'TxInvalid':
                this.handleTxInvalid(data);
                this.emit('TxInvalid', data);
                break;
            case 'HeadIsClosed':
                this.status = 'Closed';
                this.contestationDeadline = data.contestationDeadline;
                this.emit('statusChanged', this.status);
                this.emit('closed', data);
                break;
            case 'ReadyToFanout':
                this.status = 'FanoutPossible';
                this.emit('statusChanged', this.status);
                this.emit('readyToFanout', data);
                break;
            case 'HeadIsFinalized':
                this.status = 'Final';
                this.emit('statusChanged', this.status);
                this.emit('finalized', data);
                break;
            case 'HeadIsAborted':
                this.status = 'Idle';
                this.headId = null;
                this.emit('statusChanged', this.status);
                this.emit('aborted', data);
                break;
            case 'CommandFailed':
                console.error('Command failed:', JSON.stringify(data, null, 2));
                this.emit('commandFailed', data);
                break;
            case 'PostTxOnChainFailed':
                console.error('Post transaction on-chain failed:', JSON.stringify(data, null, 2));
                this.emit('postTxOnChainFailed', data);
                break;
        }

        // Always emit 'message' for generic listeners
        this.emit('message', data);
    }

    handleGreetings(data) {
        const headStatus = data.headStatus;
        if (typeof headStatus === 'string') {
            this.status = headStatus;
        } else if (headStatus?.tag) {
            this.status = headStatus.tag;
        } else {
            this.status = 'Idle';
        }

        this.snapshotNumber = data.snapshotNumber || 0;
        this.headId = data.headId || null;

        if (data.utxo) {
            this.updateUtxos(data.utxo);
        }

        console.log(`🤝 Greetings - Status: ${this.status}, Snapshot: ${this.snapshotNumber}, UTxOs: ${this.utxos.size}`);
        this.emit('statusChanged', this.status);
        this.emit('greetings', data);
    }

    updateUtxos(utxoMap) {
        this.utxos.clear();
        for (const [txIn, output] of Object.entries(utxoMap)) {
            this.utxos.set(txIn, {
                txIn,
                address: output.address,
                value: output.value,
                datum: output.datum,
                datumHash: output.datumHash,
                inlineDatum: output.inlineDatum,
            });
        }
        this.emit('utxosUpdated', Array.from(this.utxos.values()));
    }

    handleTxValid(data) {
        const txId = data.transaction?.txId || data.transactionId;
        if (txId && this.pendingTxs.has(txId)) {
            const pending = this.pendingTxs.get(txId);
            clearTimeout(pending.timeout);
            pending.resolve({ txId, valid: true });
            this.pendingTxs.delete(txId);
        }
    }

    handleTxInvalid(data) {
        const txId = data.transaction?.txId || data.transactionId;
        const reason = data.validationError?.reason || data.reason || 'Unknown error';
        if (txId && this.pendingTxs.has(txId)) {
            const pending = this.pendingTxs.get(txId);
            clearTimeout(pending.timeout);
            pending.reject(new Error(`Transaction invalid: ${reason}`));
            this.pendingTxs.delete(txId);
        }
    }

    handleSnapshotConfirmed(data) {
        const confirmed = data.snapshot?.confirmedTransactions || [];
        for (const txId of confirmed) {
            if (this.pendingTxs.has(txId)) {
                const pending = this.pendingTxs.get(txId);
                clearTimeout(pending.timeout);
                pending.resolve({ txId, valid: true, snapshot: data.snapshot });
                this.pendingTxs.delete(txId);
            }
        }
    }

    /**
     * Initialize a new Head
     */
    async initHead() {
        console.log('🚀 Initializing Hydra Head...');
        this.send({ tag: 'Init' });
    }

    /**
     * Abort Head initialization
     */
    async abort() {
        console.log('🛑 Aborting Hydra Head...');
        this.send({ tag: 'Abort' });
    }

    /**
     * Commit funds to the Head
     * @param {Object} utxo - The UTXO to commit
     */
    async commit(utxo) {
        console.log(`📥 Committing ${Object.keys(utxo).length} UTxO(s)...`);
        this.send({ tag: 'Commit', utxo });
    }

    /**
     * Submit a new transaction to the Head with confirmation tracking
     * @param {string} cborHex - The transaction CBOR in hex
     * @param {number} timeoutMs - Timeout in milliseconds
     * @returns {Promise} Resolves when tx is confirmed
     */
    async newTx(cborHex, timeoutMs = 30000) {
        if (this.status !== 'Open') {
            throw new Error('Hydra Head is not open');
        }

        const tempId = `pending_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        const startTime = Date.now();

        return new Promise((resolve, reject) => {
            const timeout = setTimeout(() => {
                this.pendingTxs.delete(tempId);
                reject(new Error('Transaction timeout'));
            }, timeoutMs);

            this.pendingTxs.set(tempId, { resolve, reject, timeout, startTime });

            console.log(`📤 Submitting transaction...`);
            this.send({ tag: 'NewTx', transaction: { cborHex } });
        }).then(result => {
            // Update stats on success
            const latency = Date.now() - startTime;
            this.updateStats(latency);
            return result;
        });
    }

    /**
     * Submit transaction without waiting for confirmation
     */
    submitTxAsync(cborHex) {
        if (this.status !== 'Open') {
            throw new Error('Hydra Head is not open');
        }
        console.log(`📤 Submitting transaction (async)...`);
        this.send({ tag: 'NewTx', transaction: { cborHex } });
    }

    /**
     * Close the Head
     */
    async closeHead() {
        console.log('🔒 Closing Hydra Head...');
        this.send({ tag: 'Close' });
    }

    /**
     * Contest a snapshot
     */
    async contest() {
        console.log('⚔️ Contesting snapshot...');
        this.send({ tag: 'Contest' });
    }

    /**
     * Fanout (finalize) the Head
     */
    async fanout() {
        console.log('🎉 Fanning out to L1...');
        this.send({ tag: 'Fanout' });
    }

    /**
     * Get UTxOs in the Head
     */
    async getUTxO() {
        this.send({ tag: 'GetUTxO' });
    }

    /**
     * Fanout (finalize) the Head
     */
    async fanout() {
        this.send({ tag: 'Fanout' });
    }

    /**
     * Send raw message to Hydra node
     */
    send(msg) {
        if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
            throw new Error('Hydra WebSocket not connected');
        }
        console.log(`📤 Sending: ${msg.tag}`);
        this.ws.send(JSON.stringify(msg));
    }

    /**
     * Register event listener
     */
    on(event, callback) {
        if (!this.callbacks[event]) {
            this.callbacks[event] = [];
        }
        this.callbacks[event].push(callback);
    }

    /**
     * Remove event listener
     */
    off(event, callback) {
        if (this.callbacks[event]) {
            this.callbacks[event] = this.callbacks[event].filter(cb => cb !== callback);
        }
    }

    /**
     * Emit event
     */
    emit(event, data) {
        if (this.callbacks[event]) {
            this.callbacks[event].forEach(cb => {
                try {
                    cb(data);
                } catch (e) {
                    console.error(`Error in ${event} callback:`, e);
                }
            });
        }

        // Interop with Dart
        if (event === 'statusChanged' && window.onHydraStatusChange) {
            window.onHydraStatusChange(data);
        }

        if (event === 'message' && window.onHydraMessage) {
            window.onHydraMessage(JSON.stringify(data));
        }

        if (event === 'utxosUpdated' && window.onHydraUtxosUpdated) {
            window.onHydraUtxosUpdated(JSON.stringify(data));
        }
    }

    /**
     * Notify Dart of connection state changes
     * @private
     */
    _notifyDartConnectionChange(isConnected) {
        // Multiple ways to notify Dart
        if (window.onHydraConnectionChange) {
            window.onHydraConnectionChange(isConnected);
        }
        // Also emit status change with full state
        if (window.onHydraStatusChange) {
            window.onHydraStatusChange(this.status);
        }
        // Log for debugging
        console.log(`🔔 Dart notified: connection=${isConnected}, status=${this.status}`);
    }

    // ============ TRADING HELPERS ============

    /**
     * Get all UTxOs in the Head
     */
    getUtxos() {
        return Array.from(this.utxos.values());
    }

    /**
     * Get UTxOs at a specific address
     */
    getUtxosAtAddress(address) {
        return this.getUtxos().filter(utxo => utxo.address === address);
    }

    /**
     * Find UTxO with enough ADA for payment
     */
    findPaymentUtxo(address, requiredLovelace) {
        const utxos = this.getUtxosAtAddress(address);
        return utxos.find(utxo => {
            const lovelace = BigInt(utxo.value?.lovelace || utxo.value?.coin || utxo.value || 0);
            return lovelace >= BigInt(requiredLovelace);
        });
    }

    /**
     * Find UTxO containing specific tokens
     */
    findTokenUtxo(address, policyId, assetName, requiredQuantity) {
        const utxos = this.getUtxosAtAddress(address);
        const assetId = `${policyId}${assetName}`;

        return utxos.find(utxo => {
            const assets = utxo.value?.assets || {};
            const quantity = BigInt(assets[assetId] || 0);
            return quantity >= BigInt(requiredQuantity);
        });
    }

    /**
     * Get property fractions (CIP-68 tokens) in the Head
     */
    getPropertyFractions() {
        const fractions = [];
        for (const utxo of this.utxos.values()) {
            const assets = utxo.value?.assets || {};
            for (const [assetId, quantity] of Object.entries(assets)) {
                // Check for CIP-68 user token prefix (000de140)
                const assetName = assetId.substring(56);
                if (assetName.startsWith('000de140')) {
                    fractions.push({
                        propertyId: assetName.substring(8),
                        fractionId: assetId,
                        policyId: assetId.substring(0, 56),
                        assetName,
                        ownerAddress: utxo.address,
                        quantity: quantity.toString(), // Convert to string for JSON safety
                        txIn: utxo.txIn,
                    });
                }
            }
        }
        return fractions;
    }

    /**
     * Update trading stats
     */
    updateStats(latencyMs) {
        this.stats.totalTrades++;
        this.stats.averageLatencyMs =
            (this.stats.averageLatencyMs * (this.stats.totalTrades - 1) + latencyMs) / this.stats.totalTrades;

        const now = Math.floor(Date.now() / 1000);
        this.tpsWindow.push(now);
        this.tpsWindow = this.tpsWindow.filter(t => now - t < 60);
        this.stats.currentTps = this.tpsWindow.length / 60;

        if (this.stats.currentTps > this.stats.peakTps) {
            this.stats.peakTps = this.stats.currentTps;
        }

        this.emit('statsUpdated', this.stats);
    }

    /**
     * Get current status
     */
    getStatus() {
        return this.status;
    }

    /**
     * Get Head ID
     */
    getHeadId() {
        return this.headId;
    }

    /**
     * Get snapshot number
     */
    getSnapshotNumber() {
        return this.snapshotNumber;
    }

    /**
     * Get trading stats (with BigInt converted to string)
     */
    getStats() {
        return {
            ...this.stats,
            totalVolume: this.stats.totalVolume.toString()
        };
    }

    /**
     * Check if Head is open
     */
    isOpen() {
        return this.status === 'Open';
    }

    /**
     * Check if connected
     */
    isConnected() {
        return this.ws && this.ws.readyState === WebSocket.OPEN;
    }

    /**
     * Get message history
     */
    getHistory() {
        return this.history;
    }

    /**
     * Get full state for Dart interop (as JSON string)
     */
    getState() {
        return {
            status: this.status,
            headId: this.headId,
            snapshotNumber: this.snapshotNumber,
            utxoCount: this.utxos.size,
            parties: this.parties,
            stats: {
                totalTrades: this.stats.totalTrades,
                totalVolume: this.stats.totalVolume.toString(), // Convert BigInt to string
                averageLatencyMs: this.stats.averageLatencyMs,
                peakTps: this.stats.peakTps,
                currentTps: this.stats.currentTps,
            },
            isConnected: this.isConnected(),
        };
    }

    /**
     * Get state as plain object for Dart interop
     * BigInt values are converted to strings for JSON safety
     */
    getStateJson() {
        const state = this.getState();
        // Return plain object - Dart will handle conversion
        return state;
    }

    /**
     * Get property fractions as plain array for Dart interop
     */
    getPropertyFractionsJson() {
        const fractions = this.getPropertyFractions();
        // Return plain array - Dart will handle conversion
        return fractions;
    }
}

// Expose to window
window.HydraClient = HydraClient;
window.hydraClient = new HydraClient();

// Helper function for Dart interop - ensures string is returned properly
window.hydraGetStateString = function () {
    const state = window.hydraClient.getState();
    return JSON.stringify(state, (key, value) =>
        typeof value === 'bigint' ? value.toString() : value
    );
};

window.hydraGetFractionsString = function () {
    const fractions = window.hydraClient.getPropertyFractions();
    return JSON.stringify(fractions, (key, value) =>
        typeof value === 'bigint' ? value.toString() : value
    );
};

window.hydraGetUtxosString = function () {
    const utxos = window.hydraClient.getUtxos();
    return JSON.stringify(utxos, (key, value) =>
        typeof value === 'bigint' ? value.toString() : value
    );
};

console.log('✅ Hydra Client loaded (Production)');
