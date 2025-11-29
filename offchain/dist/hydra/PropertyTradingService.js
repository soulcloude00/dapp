"use strict";
/**
 * Property Trading Service for Hydra L2
 * Handles instant property fraction trading within Hydra Head
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.PropertyTradingService = void 0;
const events_1 = require("events");
// ============================================================================
// Property Trading Service
// ============================================================================
class PropertyTradingService extends events_1.EventEmitter {
    constructor(hydra) {
        super();
        this.activeOrders = new Map();
        this.orderBooks = new Map();
        this.tpsWindow = [];
        this.TPS_WINDOW_SIZE = 60; // 60 seconds
        this.hydra = hydra;
        this.stats = {
            totalTrades: 0,
            totalVolume: BigInt(0),
            averageLatencyMs: 0,
            peakTps: 0,
            currentTps: 0,
        };
        this.setupEventListeners();
    }
    setupEventListeners() {
        this.hydra.on('txValid', (message) => {
            this.handleTxConfirmed(message);
        });
        this.hydra.on('txInvalid', (message) => {
            this.handleTxFailed(message);
        });
        this.hydra.on('snapshotConfirmed', (message) => {
            this.updateOrderBooks();
            this.emit('snapshotConfirmed', message);
        });
        this.hydra.on('utxosUpdated', () => {
            this.updateOrderBooks();
        });
    }
    // ============================================================================
    // Trading Operations
    // ============================================================================
    /**
     * Get all property fractions available in the Hydra Head
     */
    getAvailableFractions() {
        const fractions = [];
        const utxos = this.hydra.getUtxos();
        for (const utxo of utxos) {
            if (utxo.value.assets) {
                for (const [assetId, quantity] of Object.entries(utxo.value.assets)) {
                    // Parse asset ID (policyId + assetName)
                    const policyId = assetId.substring(0, 56);
                    const assetName = assetId.substring(56);
                    // Check if this is a property fraction token
                    if (this.isPropertyFractionToken(policyId, assetName)) {
                        fractions.push({
                            propertyId: this.extractPropertyId(assetName),
                            fractionId: assetId,
                            policyId,
                            assetName,
                            ownerAddress: utxo.address,
                            quantity,
                            metadata: this.getPropertyMetadata(utxo),
                        });
                    }
                }
            }
        }
        return fractions;
    }
    /**
     * Get fractions owned by a specific address
     */
    getFractionsAtAddress(address) {
        return this.getAvailableFractions().filter((f) => f.ownerAddress === address);
    }
    /**
     * Place a buy order for property fractions
     */
    async placeBuyOrder(propertyId, policyId, assetName, quantity, pricePerUnit, buyerAddress) {
        const orderId = this.generateOrderId();
        const totalPrice = quantity * pricePerUnit;
        const order = {
            orderId,
            propertyId,
            fractionPolicyId: policyId,
            fractionAssetName: assetName,
            seller: '', // Will be filled when matched
            buyer: buyerAddress,
            quantity,
            pricePerUnit,
            totalPrice,
            timestamp: Date.now(),
            status: 'pending',
        };
        // Add to order book
        this.addToOrderBook(propertyId, 'bid', {
            address: buyerAddress,
            quantity,
            pricePerUnit,
            timestamp: order.timestamp,
        });
        this.activeOrders.set(orderId, order);
        this.emit('orderPlaced', order);
        // Try to match with existing asks
        await this.matchOrders(propertyId);
        return order;
    }
    /**
     * Place a sell order for property fractions
     */
    async placeSellOrder(propertyId, policyId, assetName, quantity, pricePerUnit, sellerAddress) {
        // Verify seller has the fractions
        const sellerFractions = this.getFractionsAtAddress(sellerAddress);
        const hasEnough = sellerFractions.some((f) => f.policyId === policyId && f.assetName === assetName && f.quantity >= quantity);
        if (!hasEnough) {
            throw new Error('Insufficient fraction balance');
        }
        const orderId = this.generateOrderId();
        const totalPrice = quantity * pricePerUnit;
        const order = {
            orderId,
            propertyId,
            fractionPolicyId: policyId,
            fractionAssetName: assetName,
            seller: sellerAddress,
            buyer: '', // Will be filled when matched
            quantity,
            pricePerUnit,
            totalPrice,
            timestamp: Date.now(),
            status: 'pending',
        };
        // Add to order book
        this.addToOrderBook(propertyId, 'ask', {
            address: sellerAddress,
            quantity,
            pricePerUnit,
            timestamp: order.timestamp,
        });
        this.activeOrders.set(orderId, order);
        this.emit('orderPlaced', order);
        // Try to match with existing bids
        await this.matchOrders(propertyId);
        return order;
    }
    /**
     * Execute an instant trade (market order)
     */
    async executeInstantTrade(sellerAddress, buyerAddress, policyId, assetName, quantity, totalPrice, txCborHex) {
        const startTime = Date.now();
        const order = {
            orderId: this.generateOrderId(),
            propertyId: this.extractPropertyId(assetName),
            fractionPolicyId: policyId,
            fractionAssetName: assetName,
            seller: sellerAddress,
            buyer: buyerAddress,
            quantity,
            pricePerUnit: totalPrice / quantity,
            totalPrice,
            timestamp: startTime,
            status: 'submitted',
        };
        this.activeOrders.set(order.orderId, order);
        this.emit('tradeSubmitted', order);
        try {
            // Submit to Hydra
            const result = await this.hydra.submitTx(txCborHex);
            // Update stats
            const latency = Date.now() - startTime;
            this.updateStats(totalPrice, latency);
            order.status = 'confirmed';
            this.emit('tradeConfirmed', { order, result, latencyMs: latency });
            return result;
        }
        catch (error) {
            order.status = 'failed';
            this.emit('tradeFailed', { order, error });
            throw error;
        }
    }
    /**
     * Cancel an active order
     */
    cancelOrder(orderId) {
        const order = this.activeOrders.get(orderId);
        if (!order || order.status !== 'pending') {
            return false;
        }
        // Remove from order book
        const orderBook = this.orderBooks.get(order.propertyId);
        if (orderBook) {
            if (order.buyer) {
                orderBook.bids = orderBook.bids.filter((b) => b.address !== order.buyer || b.quantity !== order.quantity);
            }
            if (order.seller) {
                orderBook.asks = orderBook.asks.filter((a) => a.address !== order.seller || a.quantity !== order.quantity);
            }
        }
        this.activeOrders.delete(orderId);
        this.emit('orderCancelled', order);
        return true;
    }
    // ============================================================================
    // Order Matching
    // ============================================================================
    async matchOrders(propertyId) {
        const orderBook = this.orderBooks.get(propertyId);
        if (!orderBook || orderBook.bids.length === 0 || orderBook.asks.length === 0) {
            return;
        }
        // Sort bids (highest first) and asks (lowest first)
        const sortedBids = [...orderBook.bids].sort((a, b) => Number(b.pricePerUnit - a.pricePerUnit));
        const sortedAsks = [...orderBook.asks].sort((a, b) => Number(a.pricePerUnit - b.pricePerUnit));
        // Match orders where bid >= ask
        for (const bid of sortedBids) {
            for (const ask of sortedAsks) {
                if (bid.pricePerUnit >= ask.pricePerUnit) {
                    const matchedQuantity = bid.quantity < ask.quantity ? bid.quantity : ask.quantity;
                    const matchedPrice = ask.pricePerUnit; // Execute at ask price
                    this.emit('orderMatched', {
                        buyer: bid.address,
                        seller: ask.address,
                        quantity: matchedQuantity,
                        pricePerUnit: matchedPrice,
                        totalPrice: matchedQuantity * matchedPrice,
                    });
                    // In real implementation, this would trigger transaction building
                    // For now, we emit the match event for the frontend to handle
                }
            }
        }
    }
    // ============================================================================
    // Order Book Management
    // ============================================================================
    getOrderBook(propertyId) {
        return this.orderBooks.get(propertyId);
    }
    addToOrderBook(propertyId, side, entry) {
        let orderBook = this.orderBooks.get(propertyId);
        if (!orderBook) {
            orderBook = { propertyId, bids: [], asks: [] };
            this.orderBooks.set(propertyId, orderBook);
        }
        if (side === 'bid') {
            orderBook.bids.push(entry);
        }
        else {
            orderBook.asks.push(entry);
        }
        this.emit('orderBookUpdated', orderBook);
    }
    updateOrderBooks() {
        // Update order books based on current UTxO set
        const fractions = this.getAvailableFractions();
        for (const fraction of fractions) {
            let orderBook = this.orderBooks.get(fraction.propertyId);
            if (!orderBook) {
                orderBook = { propertyId: fraction.propertyId, bids: [], asks: [] };
                this.orderBooks.set(fraction.propertyId, orderBook);
            }
        }
        this.emit('orderBooksRefreshed', Array.from(this.orderBooks.values()));
    }
    // ============================================================================
    // Statistics
    // ============================================================================
    getStats() {
        return { ...this.stats };
    }
    updateStats(volume, latencyMs) {
        this.stats.totalTrades++;
        this.stats.totalVolume += volume;
        // Rolling average latency
        this.stats.averageLatencyMs =
            (this.stats.averageLatencyMs * (this.stats.totalTrades - 1) + latencyMs) /
                this.stats.totalTrades;
        // TPS calculation (trades per second over window)
        const now = Math.floor(Date.now() / 1000);
        this.tpsWindow.push(now);
        this.tpsWindow = this.tpsWindow.filter((t) => now - t < this.TPS_WINDOW_SIZE);
        this.stats.currentTps = this.tpsWindow.length / this.TPS_WINDOW_SIZE;
        if (this.stats.currentTps > this.stats.peakTps) {
            this.stats.peakTps = this.stats.currentTps;
        }
        this.emit('statsUpdated', this.stats);
    }
    // ============================================================================
    // Helpers
    // ============================================================================
    handleTxConfirmed(message) {
        const txId = message.transaction?.txId;
        for (const [orderId, order] of this.activeOrders) {
            if (order.status === 'submitted') {
                order.status = 'confirmed';
                this.emit('orderConfirmed', order);
            }
        }
    }
    handleTxFailed(message) {
        for (const [orderId, order] of this.activeOrders) {
            if (order.status === 'submitted') {
                order.status = 'failed';
                this.emit('orderFailed', { order, reason: message.validationError?.reason });
            }
        }
    }
    isPropertyFractionToken(policyId, assetName) {
        // Check if asset name starts with CIP-68 user token prefix (000de140)
        return assetName.startsWith('000de140');
    }
    extractPropertyId(assetName) {
        // Remove CIP-68 prefix to get property ID
        if (assetName.startsWith('000de140')) {
            return assetName.substring(8);
        }
        return assetName;
    }
    getPropertyMetadata(utxo) {
        if (utxo.inlineDatum || utxo.datum) {
            const datum = utxo.inlineDatum || utxo.datum;
            // Parse CIP-68 metadata from datum
            // This would need to match your actual datum structure
            try {
                return {
                    name: datum.name || 'Unknown Property',
                    location: datum.location,
                    totalFractions: datum.total_fractions || 0,
                    pricePerFraction: BigInt(datum.price_per_fraction || 0),
                    imageUrl: datum.image,
                };
            }
            catch {
                return undefined;
            }
        }
        return undefined;
    }
    generateOrderId() {
        return `order_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }
}
exports.PropertyTradingService = PropertyTradingService;
