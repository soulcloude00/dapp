
import {
    MeshTxBuilder,
    BlockfrostProvider,
    deserializeAddress,
} from '@meshsdk/core';

// Hydra Head Status
export type HydraHeadStatus =
    | 'Idle'
    | 'Initializing'
    | 'Open'
    | 'Closed'
    | 'FanoutPossible'
    | 'Final';

// Basic Hydra Message Types
export interface HydraMessage {
    tag: string;
    [key: string]: any;
}

export class HydraManager {
    private ws: WebSocket | null = null;
    private url: string;
    private status: HydraHeadStatus = 'Idle';
    private callbacks: { [key: string]: (data: any) => void } = {};

    constructor(url: string = 'ws://localhost:4001') {
        this.url = url;
    }

    /**
     * Connect to the Hydra Node
     */
    connect(): Promise<void> {
        return new Promise((resolve, reject) => {
            try {
                this.ws = new WebSocket(this.url);

                this.ws.onopen = () => {
                    console.log('Connected to Hydra Node at', this.url);
                    resolve();
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
                    reject(error);
                };

                this.ws.onclose = () => {
                    console.log('Disconnected from Hydra Node');
                    this.status = 'Idle';
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
    private handleMessage(data: HydraMessage) {
        console.log('Hydra Message:', data.tag, data);

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

    private updateStatus(headStatus: any) {
        // Map Hydra internal status to our simplified status
        // This logic might need adjustment based on exact Hydra version
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
     * @param utxo - The UTXO to commit (format depends on Hydra version, usually generic map)
     */
    async commit(utxo: any) {
        this.send({ tag: 'Commit', utxo });
    }

    /**
     * Submit a new transaction to the Head
     * @param cborHex - The transaction CBOR in hex
     */
    async newTx(cborHex: string) {
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
    send(msg: any) {
        if (!this.ws || this.ws.readyState !== WebSocket.OPEN) {
            throw new Error('Hydra WebSocket not connected');
        }
        this.ws.send(JSON.stringify(msg));
    }

    /**
     * Register event listener
     */
    on(event: string, callback: (data: any) => void) {
        this.callbacks[event] = callback;
    }

    /**
     * Emit event
     */
    private emit(event: string, data: any) {
        if (this.callbacks[event]) {
            this.callbacks[event](data);
        }
    }

    /**
     * Get current status
     */
    getStatus(): HydraHeadStatus {
        return this.status;
    }
}

// Export singleton for simple usage, but class is also exported
export const hydraManager = new HydraManager();
