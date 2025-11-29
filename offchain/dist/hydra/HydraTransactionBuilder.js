"use strict";
/**
 * Transaction Builder for Hydra L2 Property Trading
 * Builds Cardano transactions for property fraction trades within Hydra
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.HydraTransactionBuilder = void 0;
const core_1 = require("@meshsdk/core");
// ============================================================================
// Transaction Builder
// ============================================================================
class HydraTransactionBuilder {
    constructor(hydra, wallet) {
        this.hydra = hydra;
        this.wallet = wallet;
    }
    /**
     * Build a property fraction trade transaction
     * Seller sends fraction tokens, buyer sends ADA
     */
    async buildTradeTx(params) {
        const { seller, buyer, policyId, assetName, quantity, priceLovelace, sellerUtxo, buyerUtxo, } = params;
        const assetUnit = `${policyId}${assetName}`;
        const asset = {
            unit: assetUnit,
            quantity: quantity.toString(),
        };
        const txBuilder = new core_1.MeshTxBuilder();
        // Input: Seller's UTxO with the fraction tokens
        txBuilder.txIn(this.parseUtxoTxHash(sellerUtxo.txIn), this.parseUtxoTxIndex(sellerUtxo.txIn));
        // Input: Buyer's UTxO with ADA
        txBuilder.txIn(this.parseUtxoTxHash(buyerUtxo.txIn), this.parseUtxoTxIndex(buyerUtxo.txIn));
        // Output: Buyer receives fraction tokens with min ADA
        txBuilder.txOut(buyer, [
            { unit: 'lovelace', quantity: '2000000' },
            asset,
        ]);
        // Output: Seller receives ADA payment
        txBuilder.txOut(seller, [
            { unit: 'lovelace', quantity: priceLovelace.toString() },
        ]);
        // Change goes back to buyer (remaining ADA after payment)
        txBuilder.changeAddress(buyer);
        // Build the transaction
        const unsignedTx = await txBuilder.complete();
        return unsignedTx;
    }
    /**
     * Build a simple token transfer transaction (within Hydra)
     */
    async buildTransferTx(params) {
        const { from, to, policyId, assetName, quantity, sourceUtxo } = params;
        const assetUnit = `${policyId}${assetName}`;
        const asset = {
            unit: assetUnit,
            quantity: quantity.toString(),
        };
        const txBuilder = new core_1.MeshTxBuilder();
        // Input: Source UTxO
        txBuilder.txIn(this.parseUtxoTxHash(sourceUtxo.txIn), this.parseUtxoTxIndex(sourceUtxo.txIn));
        // Output: Recipient receives tokens with min ADA
        txBuilder.txOut(to, [
            { unit: 'lovelace', quantity: '2000000' },
            asset,
        ]);
        // Change back to sender
        txBuilder.changeAddress(from);
        const unsignedTx = await txBuilder.complete();
        return unsignedTx;
    }
    /**
     * Build ADA transfer transaction (within Hydra)
     */
    async buildAdaTransferTx(from, to, amountLovelace, sourceUtxo) {
        const txBuilder = new core_1.MeshTxBuilder();
        txBuilder.txIn(this.parseUtxoTxHash(sourceUtxo.txIn), this.parseUtxoTxIndex(sourceUtxo.txIn));
        // Output: Recipient receives ADA
        txBuilder.txOut(to, [
            { unit: 'lovelace', quantity: amountLovelace.toString() },
        ]);
        txBuilder.changeAddress(from);
        const unsignedTx = await txBuilder.complete();
        return unsignedTx;
    }
    /**
     * Build commit transaction for initial UTxO commitment to Head
     */
    buildCommitUtxoMap(utxos) {
        const commitMap = {};
        for (const utxo of utxos) {
            const txIn = `${utxo.input.txHash}#${utxo.input.outputIndex}`;
            const value = {
                lovelace: utxo.output.amount.find((a) => a.unit === 'lovelace')?.quantity || '0',
            };
            // Add assets
            const assets = utxo.output.amount.filter((a) => a.unit !== 'lovelace');
            if (assets.length > 0) {
                value.assets = {};
                for (const asset of assets) {
                    value.assets[asset.unit] = asset.quantity;
                }
            }
            commitMap[txIn] = {
                address: utxo.output.address,
                value,
                datum: utxo.output.plutusData,
                datumHash: utxo.output.dataHash,
            };
        }
        return commitMap;
    }
    /**
     * Sign a transaction with the wallet
     */
    async signTx(unsignedTx) {
        return await this.wallet.signTx(unsignedTx);
    }
    /**
     * Build and submit a trade in one call
     */
    async executeTradeInHydra(params) {
        // Build the transaction
        const unsignedTx = await this.buildTradeTx(params);
        // Sign it
        const signedTx = await this.signTx(unsignedTx);
        // Submit to Hydra
        const result = await this.hydra.submitTx(signedTx);
        return result.txId;
    }
    // ============================================================================
    // Helpers
    // ============================================================================
    parseUtxoTxHash(txIn) {
        return txIn.split('#')[0];
    }
    parseUtxoTxIndex(txIn) {
        return parseInt(txIn.split('#')[1], 10);
    }
    /**
     * Find suitable UTxO for a trade (has enough ADA)
     */
    findPaymentUtxo(address, requiredLovelace) {
        const utxos = this.hydra.getUtxosAtAddress(address);
        return utxos.find((utxo) => utxo.value.lovelace >= requiredLovelace);
    }
    /**
     * Find UTxO containing specific tokens
     */
    findTokenUtxo(address, policyId, assetName, requiredQuantity) {
        const utxos = this.hydra.getUtxosAtAddress(address);
        const assetId = `${policyId}${assetName}`;
        return utxos.find((utxo) => {
            const assets = utxo.value.assets;
            if (!assets)
                return false;
            const quantity = assets[assetId];
            return quantity !== undefined && quantity >= requiredQuantity;
        });
    }
}
exports.HydraTransactionBuilder = HydraTransactionBuilder;
