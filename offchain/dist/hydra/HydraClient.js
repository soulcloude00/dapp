"use strict";
/**
 * Production-Ready Hydra Client for PropFi
 * Handles WebSocket connection to Hydra Node with reconnection, event handling, and UTxO management
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.hydraClient = exports.HydraClient = void 0;
const events_1 = require("events");
// ============================================================================
// Hydra Client Implementation
// ============================================================================
class HydraClient extends events_1.EventEmitter {
    constructor(config = {}) {
        super();
        this.ws = null;
        this.reconnectAttempts = 0;
        this.reconnectTimeout = null;
        this.heartbeatInterval = null;
        this.messageSeq = 0;
        this.pendingTxs = new Map();
        this.config = {
            apiUrl: config.apiUrl || 'ws://localhost:4001',
            reconnectInterval: config.reconnectInterval || 5000,
            maxReconnectAttempts: config.maxReconnectAttempts || 10,
            heartbeatInterval: config.heartbeatInterval || 30000,
        };
        this.state = {
            status: 'Disconnected',
            headId: null,
            snapshotNumber: 0,
            utxos: new Map(),
            parties: [],
        };
    }
    // ============================================================================
    // Connection Management
    // ============================================================================
    async connect() {
        return new Promise((resolve, reject) => {
            try {
                console.log(`🔌 Connecting to Hydra node at ${this.config.apiUrl}...`);
                this.ws = new WebSocket(this.config.apiUrl);
                const connectionTimeout = setTimeout(() => {
                    reject(new Error('Connection timeout'));
                    this.ws?.close();
                }, 10000);
                this.ws.onopen = () => {
                    clearTimeout(connectionTimeout);
                    console.log('✅ Connected to Hydra node');
                    this.reconnectAttempts = 0;
                    this.startHeartbeat();
                    this.emit('connected');
                    resolve();
                };
                this.ws.onmessage = (event) => {
                    this.handleMessage(event.data.toString());
                };
                this.ws.onclose = (event) => {
                    console.log(`❌ Disconnected from Hydra node (code: ${event.code})`);
                    this.stopHeartbeat();
                    this.state.status = 'Disconnected';
                    this.emit('disconnected', event);
                    this.attemptReconnect();
                };
                this.ws.onerror = (error) => {
                    console.error('Hydra WebSocket error:', error);
                    this.emit('error', error);
                };
            }
            catch (error) {
                reject(error);
            }
        });
    }
    disconnect() {
        this.stopHeartbeat();
        if (this.reconnectTimeout) {
            clearTimeout(this.reconnectTimeout);
            this.reconnectTimeout = null;
        }
        if (this.ws) {
            this.ws.close(1000, 'Client disconnect');
            this.ws = null;
        }
        this.state.status = 'Disconnected';
        this.emit('disconnected', { code: 1000, reason: 'Client disconnect' });
    }
    attemptReconnect() {
        if (this.reconnectAttempts >= this.config.maxReconnectAttempts) {
            console.error('❌ Max reconnection attempts reached');
            this.emit('maxReconnectAttempts');
            return;
        }
        this.reconnectAttempts++;
        console.log(`🔄 Reconnecting (${this.reconnectAttempts}/${this.config.maxReconnectAttempts})...`);
        this.reconnectTimeout = setTimeout(() => {
            this.connect().catch((error) => {
                console.error('Reconnection failed:', error);
            });
        }, this.config.reconnectInterval);
    }
    startHeartbeat() {
        this.heartbeatInterval = setInterval(() => {
            if (this.ws?.readyState === WebSocket.OPEN) {
                // Hydra doesn't have a ping command, but we can check the connection
                this.emit('heartbeat');
            }
        }, this.config.heartbeatInterval);
    }
    stopHeartbeat() {
        if (this.heartbeatInterval) {
            clearInterval(this.heartbeatInterval);
            this.heartbeatInterval = null;
        }
    }
    // ============================================================================
    // Message Handling
    // ============================================================================
    handleMessage(data) {
        try {
            const message = JSON.parse(data);
            this.messageSeq = message.seq || this.messageSeq;
            console.log(`📨 [${message.seq || '-'}] ${message.tag}`);
            switch (message.tag) {
                case 'Greetings':
                    this.handleGreetings(message);
                    break;
                case 'HeadIsInitializing':
                    this.state.status = 'Initializing';
                    this.state.headId = message.headId || null;
                    this.state.parties = message.parties || [];
                    this.emit('initializing', message);
                    break;
                case 'Committed':
                    this.emit('committed', message);
                    break;
                case 'HeadIsOpen':
                    this.state.status = 'Open';
                    this.state.headId = message.headId || null;
                    if (message.utxo) {
                        this.updateUtxos(message.utxo);
                    }
                    this.emit('open', message);
                    break;
                case 'SnapshotConfirmed':
                    this.state.snapshotNumber = message.snapshot?.snapshotNumber || 0;
                    if (message.snapshot?.utxo) {
                        this.updateUtxos(message.snapshot.utxo);
                    }
                    this.handleSnapshotConfirmed(message);
                    this.emit('snapshotConfirmed', message);
                    break;
                case 'TxValid':
                    this.handleTxValid(message);
                    this.emit('txValid', message);
                    break;
                case 'TxInvalid':
                    this.handleTxInvalid(message);
                    this.emit('txInvalid', message);
                    break;
                case 'HeadIsClosed':
                    this.state.status = 'Closed';
                    this.state.contestationDeadline = message.contestationDeadline;
                    this.emit('closed', message);
                    break;
                case 'ReadyToFanout':
                    this.state.status = 'FanoutPossible';
                    this.emit('readyToFanout', message);
                    break;
                case 'HeadIsFinalized':
                    this.state.status = 'Final';
                    this.emit('finalized', message);
                    break;
                case 'HeadIsAborted':
                    this.state.status = 'Idle';
                    this.state.headId = null;
                    this.emit('aborted', message);
                    break;
                case 'CommandFailed':
                    console.error('Command failed:', message);
                    this.emit('commandFailed', message);
                    break;
                case 'PostTxOnChainFailed':
                    console.error('On-chain tx failed:', message);
                    this.emit('postTxFailed', message);
                    break;
                default:
                    this.emit('message', message);
            }
        }
        catch (error) {
            console.error('Failed to parse Hydra message:', error);
            this.emit('parseError', { error, data });
        }
    }
    handleGreetings(message) {
        const headStatus = message.headStatus;
        if (typeof headStatus === 'string') {
            this.state.status = headStatus;
        }
        else if (headStatus?.tag) {
            this.state.status = headStatus.tag;
        }
        this.state.snapshotNumber = message.snapshotNumber || 0;
        this.state.headId = message.headId || null;
        if (message.utxo) {
            this.updateUtxos(message.utxo);
        }
        console.log(`🤝 Greetings - Head status: ${this.state.status}, Snapshot: ${this.state.snapshotNumber}`);
        this.emit('greetings', message);
        this.emit('statusChanged', this.state.status);
    }
    handleTxValid(message) {
        const txId = message.transaction?.txId || message.transactionId;
        if (txId && this.pendingTxs.has(txId)) {
            const pending = this.pendingTxs.get(txId);
            clearTimeout(pending.timeout);
            pending.resolve({ txId, valid: true });
            this.pendingTxs.delete(txId);
        }
    }
    handleTxInvalid(message) {
        const txId = message.transaction?.txId || message.transactionId;
        const reason = message.validationError?.reason || message.reason || 'Unknown error';
        if (txId && this.pendingTxs.has(txId)) {
            const pending = this.pendingTxs.get(txId);
            clearTimeout(pending.timeout);
            pending.reject(new Error(`Transaction invalid: ${reason}`));
            this.pendingTxs.delete(txId);
        }
    }
    handleSnapshotConfirmed(message) {
        // Resolve all pending transactions that are in the confirmed list
        const confirmed = message.snapshot?.confirmedTransactions || [];
        for (const txId of confirmed) {
            if (this.pendingTxs.has(txId)) {
                const pending = this.pendingTxs.get(txId);
                clearTimeout(pending.timeout);
                pending.resolve({ txId, valid: true, snapshot: message.snapshot });
                this.pendingTxs.delete(txId);
            }
        }
    }
    updateUtxos(utxoMap) {
        this.state.utxos.clear();
        for (const [txIn, output] of Object.entries(utxoMap)) {
            const value = {
                lovelace: BigInt(output.value?.lovelace || output.value?.coin || output.value || 0),
            };
            // Parse multi-assets
            if (output.value?.assets) {
                value.assets = {};
                for (const [assetId, quantity] of Object.entries(output.value.assets)) {
                    value.assets[assetId] = BigInt(quantity);
                }
            }
            this.state.utxos.set(txIn, {
                txIn,
                address: output.address,
                value,
                datum: output.datum,
                datumHash: output.datumHash,
                inlineDatum: output.inlineDatum,
                referenceScript: output.referenceScript,
            });
        }
        this.emit('utxosUpdated', this.state.utxos);
    }
    // ============================================================================
    // Hydra Commands
    // ============================================================================
    /**
     * Initialize a new Hydra Head
     */
    init() {
        console.log('🚀 Initializing Hydra Head...');
        this.sendCommand({ tag: 'Init' });
    }
    /**
     * Abort the Head initialization
     */
    abort() {
        console.log('🛑 Aborting Hydra Head...');
        this.sendCommand({ tag: 'Abort' });
    }
    /**
     * Commit UTxOs to the Head
     * @param utxos - Map of UTxOs to commit (txIn -> output)
     */
    commit(utxos) {
        console.log(`📥 Committing ${Object.keys(utxos).length} UTxO(s)...`);
        this.sendCommand({ tag: 'Commit', utxo: utxos });
    }
    /**
     * Submit a transaction to the Hydra Head
     * @param cborHex - Transaction CBOR in hex format
     * @param timeoutMs - Timeout in milliseconds (default: 30000)
     * @returns Promise that resolves when tx is valid or rejects on invalid/timeout
     */
    async submitTx(cborHex, timeoutMs = 30000) {
        if (!this.isOpen()) {
            throw new Error('Hydra Head is not open');
        }
        // Generate a temporary ID for tracking (actual ID comes from Hydra)
        const tempId = `pending_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        return new Promise((resolve, reject) => {
            const timeout = setTimeout(() => {
                this.pendingTxs.delete(tempId);
                reject(new Error('Transaction submission timeout'));
            }, timeoutMs);
            this.pendingTxs.set(tempId, { resolve, reject, timeout });
            // Listen for the actual txId when TxValid comes back
            const txValidHandler = (message) => {
                const actualTxId = message.transaction?.txId;
                if (actualTxId && this.pendingTxs.has(tempId)) {
                    // Move the pending entry to the actual txId
                    const pending = this.pendingTxs.get(tempId);
                    this.pendingTxs.delete(tempId);
                    this.pendingTxs.set(actualTxId, pending);
                }
                this.removeListener('txValid', txValidHandler);
            };
            this.on('txValid', txValidHandler);
            console.log(`📤 Submitting transaction...`);
            this.sendCommand({
                tag: 'NewTx',
                transaction: { cborHex },
            });
        });
    }
    /**
     * Close the Hydra Head
     */
    close() {
        console.log('🔒 Closing Hydra Head...');
        this.sendCommand({ tag: 'Close' });
    }
    /**
     * Contest a snapshot (if needed during contestation period)
     */
    contest() {
        console.log('⚔️ Contesting snapshot...');
        this.sendCommand({ tag: 'Contest' });
    }
    /**
     * Fanout the final UTxO set back to L1
     */
    fanout() {
        console.log('🎉 Fanning out to L1...');
        this.sendCommand({ tag: 'Fanout' });
    }
    /**
     * Get UTxOs at a specific address within the Head
     */
    getUtxo() {
        this.sendCommand({ tag: 'GetUTxO' });
    }
    sendCommand(command) {
        if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
            throw new Error('Not connected to Hydra node');
        }
        const message = JSON.stringify(command);
        console.log(`📤 Sending: ${command.tag}`);
        this.ws.send(message);
    }
    // ============================================================================
    // State Accessors
    // ============================================================================
    getState() {
        return {
            ...this.state,
            utxos: new Map(this.state.utxos),
        };
    }
    getStatus() {
        return this.state.status;
    }
    getHeadId() {
        return this.state.headId;
    }
    getSnapshotNumber() {
        return this.state.snapshotNumber;
    }
    getUtxos() {
        return Array.from(this.state.utxos.values());
    }
    getUtxoByTxIn(txIn) {
        return this.state.utxos.get(txIn);
    }
    getUtxosAtAddress(address) {
        return this.getUtxos().filter((utxo) => utxo.address === address);
    }
    isConnected() {
        return this.ws?.readyState === WebSocket.OPEN;
    }
    isOpen() {
        return this.state.status === 'Open';
    }
    canFanout() {
        return this.state.status === 'FanoutPossible';
    }
}
exports.HydraClient = HydraClient;
// Export default instance
exports.hydraClient = new HydraClient();
