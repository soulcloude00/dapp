/**
 * Hydra Client for PropFi
 * Handles WebSocket connection to a Hydra Node and manages Head lifecycle.
 */

class HydraClient {
    constructor(url = 'ws://localhost:4001') {
        this.url = url;
        this.ws = null;
        this.status = 'Idle';
        this.callbacks = {};
        this.history = []; // Keep track of messages
    }

    /**
     * Connect to the Hydra Node
     */
    connect() {
        return new Promise((resolve, reject) => {
            try {
                console.log(`Connecting to Hydra Node at ${this.url}...`);
                this.ws = new WebSocket(this.url);

                this.ws.onopen = () => {
                    console.log('Connected to Hydra Node');
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
                    // Don't reject here as it might happen after connection
                };

                this.ws.onclose = () => {
                    console.log('Disconnected from Hydra Node');
                    this.status = 'Idle';
                    this.emit('statusChanged', this.status);
                };
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     * Disconnect from the Hydra Node
     */
    disconnect() {
        if (this.ws) {
            this.ws.close();
            this.ws = null;
        }
    }

    /**
     * Handle incoming Hydra messages
     */
    handleMessage(data) {
        console.log('Hydra Message:', data.tag, data);
        this.history.push({ timestamp: Date.now(), ...data });

        switch (data.tag) {
            case 'Greetings':
                this.updateStatus(data.headStatus);
                break;
            case 'HeadIsInitializing':
                this.status = 'Initializing';
                this.emit('statusChanged', this.status);
                break;
            case 'HeadIsOpen':
                this.status = 'Open';
                this.emit('statusChanged', this.status);
                break;
            case 'HeadIsClosed':
                this.status = 'Closed';
                this.emit('statusChanged', this.status);
                break;
            case 'HeadIsFinalized':
                this.status = 'Final';
                this.emit('statusChanged', this.status);
                break;
            case 'TxValid':
            case 'TxInvalid':
            case 'SnapshotConfirmed':
                this.emit(data.tag, data);
                break;
        }

        // Always emit 'message' for generic listeners
        this.emit('message', data);
    }

    updateStatus(headStatus) {
        // Map Hydra internal status to our simplified status
        if (!headStatus) return;

        if (headStatus.tag === 'Idle') this.status = 'Idle';
        else if (headStatus.tag === 'Initializing') this.status = 'Initializing';
        else if (headStatus.tag === 'Open') this.status = 'Open';
        else if (headStatus.tag === 'Closed') this.status = 'Closed';
        else this.status = 'Idle'; // Default

        this.emit('statusChanged', this.status);
    }

    /**
     * Initialize a new Head
     */
    async initHead() {
        this.send({ tag: 'Init' });
    }

    /**
     * Commit funds to the Head
     * @param {Object} utxo - The UTXO to commit
     */
    async commit(utxo) {
        this.send({ tag: 'Commit', utxo });
    }

    /**
     * Submit a new transaction to the Head
     * @param {string} cborHex - The transaction CBOR in hex
     */
    async newTx(cborHex) {
        this.send({ tag: 'NewTx', transaction: { type: 'HexCBOR', cbor: cborHex } });
    }

    /**
     * Close the Head
     */
    async closeHead() {
        this.send({ tag: 'Close' });
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
        this.ws.send(JSON.stringify(msg));
    }

    /**
     * Register event listener
     */
    on(event, callback) {
        this.callbacks[event] = callback;
    }

    /**
     * Emit event
     */
    emit(event, data) {
        if (this.callbacks[event]) {
            this.callbacks[event](data);
        }

        // Interop with Dart
        if (event === 'statusChanged' && window.onHydraStatusChange) {
            window.onHydraStatusChange(data);
        }

        if (event === 'message' && window.onHydraMessage) {
            // Pass as JSON string to avoid object mapping issues in Dart
            window.onHydraMessage(JSON.stringify(data));
        }
    }

    /**
     * Get current status
     */
    getStatus() {
        return this.status;
    }

    /**
     * Get message history
     */
    getHistory() {
        return this.history;
    }
}

// Expose to window
window.HydraClient = HydraClient;
window.hydraClient = new HydraClient(); // Singleton instance
console.log('Hydra Client loaded');
