"use strict";
/**
 * PropFi Transaction Builder
 * Builds Cardano transactions for property fractionalization and marketplace operations
 * Uses MeshJS SDK with Blockfrost Provider
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.propFiTxBuilder = exports.PropFiTransactionBuilder = exports.CIP68_USER_TOKEN_LABEL = exports.CIP68_REFERENCE_LABEL = exports.STABLECOIN_CONFIG = exports.BLOCKFROST_CONFIG = exports.NETWORK = void 0;
exports.loadContracts = loadContracts;
const core_1 = require("@meshsdk/core");
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
// ============================================================================
// Configuration
// ============================================================================
exports.NETWORK = 'preprod';
// Blockfrost configuration
exports.BLOCKFROST_CONFIG = {
    network: exports.NETWORK,
    projectId: 'preprod3EhVdYxWz9oD5XP1TVbbdLxbN4jCNwBe',
};
// Stablecoin configuration for Preprod testnet
exports.STABLECOIN_CONFIG = {
    USDM: {
        policyId: 'c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad',
        assetName: (0, core_1.stringToHex)('USDM'),
        decimals: 6,
    },
    iUSD: {
        policyId: 'f66d78b4a3cb3d37afa0ec36461e51ecbde00f26c8f0a68f94b69880',
        assetName: (0, core_1.stringToHex)('iUSD'),
        decimals: 6,
    },
};
// CIP-68 Token Labels
exports.CIP68_REFERENCE_LABEL = '000643b0'; // (100) Reference Token
exports.CIP68_USER_TOKEN_LABEL = '000de140'; // (222) User/Fraction Token
// ============================================================================
// Contract Loading
// ============================================================================
let contractConfig = null;
/**
 * Load contract configuration from plutus.json
 */
function loadContracts() {
    if (contractConfig)
        return contractConfig;
    const plutusJsonPath = path.join(__dirname, '../../contracts/plutus.json');
    if (!fs.existsSync(plutusJsonPath)) {
        throw new Error('plutus.json not found. Run `aiken build` first.');
    }
    const plutusJson = JSON.parse(fs.readFileSync(plutusJsonPath, 'utf-8'));
    const getValidator = (title) => {
        const v = plutusJson.validators.find((v) => v.title === title);
        if (!v)
            throw new Error(`Validator ${title} not found`);
        return v;
    };
    const fractionalize = getValidator('fractionalize.fractionalize.spend');
    const cip68Minting = getValidator('fractionalize.cip68_minting.mint');
    const marketplace = getValidator('fractionalize.marketplace.spend');
    contractConfig = {
        fractionalizeScriptHash: fractionalize.hash,
        fractionalizeScriptCbor: fractionalize.compiledCode,
        cip68MintingPolicyId: cip68Minting.hash,
        cip68MintingPolicyCbor: cip68Minting.compiledCode,
        marketplaceScriptHash: marketplace.hash,
        marketplaceScriptCbor: marketplace.compiledCode,
    };
    return contractConfig;
}
// ============================================================================
// Transaction Builder Class
// ============================================================================
class PropFiTransactionBuilder {
    constructor() {
        // Using Blockfrost API
        this.provider = new core_1.BlockfrostProvider(exports.BLOCKFROST_CONFIG.projectId);
        this.contracts = loadContracts();
    }
    /**
     * Get the marketplace script address
     */
    getMarketplaceAddress() {
        // Generate address from script hash
        const scriptHash = this.contracts.marketplaceScriptHash;
        // For testnet, use network ID 0
        return `addr_test1wz${scriptHash}`; // Simplified - use proper encoding in production
    }
    /**
     * Get the fractionalize script address
     */
    getFractionalizeAddress() {
        const scriptHash = this.contracts.fractionalizeScriptHash;
        return `addr_test1wz${scriptHash}`; // Simplified - use proper encoding in production
    }
    /**
     * Build CIP-68 Reference Token Datum
     */
    buildReferenceDatum(metadata) {
        // CIP-68 reference datum structure
        return (0, core_1.mConStr0)([
            // Metadata map - all values as strings/hex
            new Map([
                [(0, core_1.stringToHex)('name'), (0, core_1.stringToHex)(metadata.name)],
                [(0, core_1.stringToHex)('description'), (0, core_1.stringToHex)(metadata.description)],
                [(0, core_1.stringToHex)('image'), (0, core_1.stringToHex)(metadata.image)],
                [(0, core_1.stringToHex)('location'), (0, core_1.stringToHex)(metadata.location)],
                [(0, core_1.stringToHex)('total_value'), metadata.totalValue],
                [(0, core_1.stringToHex)('total_fractions'), metadata.totalFractions],
                [(0, core_1.stringToHex)('price_per_fraction'), metadata.pricePerFraction],
            ]),
            1, // Version
        ]);
    }
    /**
     * Build Property Datum for fractionalize validator
     */
    buildPropertyDatum(datum) {
        return (0, core_1.mConStr0)([
            datum.owner,
            datum.price,
            (0, core_1.mConStr0)([datum.fractionToken.policyId, datum.fractionToken.assetName]),
            datum.totalFractions,
            (0, core_1.mConStr0)([
                (0, core_1.stringToHex)(datum.metadata.name),
                (0, core_1.stringToHex)(datum.metadata.description),
                (0, core_1.stringToHex)(datum.metadata.location),
                datum.metadata.totalValue,
                datum.metadata.totalFractions,
            ]),
        ]);
    }
    /**
     * Build Marketplace Datum
     */
    buildMarketplaceDatum(datum) {
        return (0, core_1.mConStr0)([
            datum.seller,
            datum.price,
            (0, core_1.mConStr0)([datum.stablecoinAsset.policyId, datum.stablecoinAsset.assetName]),
            (0, core_1.mConStr0)([datum.fractionAsset.policyId, datum.fractionAsset.assetName]),
            datum.fractionAmount,
        ]);
    }
    /**
     * Fractionalize a property - Mint CIP-68 tokens
     * @param walletAddress - Owner's wallet address
     * @param propertyId - Unique property identifier (hex string)
     * @param metadata - Property metadata
     * @param totalFractions - Number of fraction tokens to mint
     */
    async fractionalizeProperty(walletAddress, propertyId, metadata, totalFractions) {
        const txBuilder = new core_1.MeshTxBuilder({
            fetcher: this.provider,
            evaluator: this.provider,
        });
        // Build token names with CIP-68 prefixes
        const referenceTokenName = exports.CIP68_REFERENCE_LABEL + propertyId;
        const userTokenName = exports.CIP68_USER_TOKEN_LABEL + propertyId;
        // Get owner's pubkey hash
        const ownerPkh = (0, core_1.deserializeAddress)(walletAddress).pubKeyHash;
        // Build the minting redeemer (MintProperty { property_id })
        const mintRedeemer = (0, core_1.mConStr0)([propertyId]);
        // Build reference datum
        const refDatum = this.buildReferenceDatum(metadata);
        // Build property datum
        const propertyDatum = this.buildPropertyDatum({
            owner: ownerPkh,
            price: metadata.pricePerFraction,
            fractionToken: {
                policyId: this.contracts.cip68MintingPolicyId,
                assetName: userTokenName,
            },
            totalFractions,
            metadata,
        });
        // Build the transaction
        const unsignedTx = await txBuilder
            .mintPlutusScriptV2()
            .mint('1', this.contracts.cip68MintingPolicyId, referenceTokenName)
            .mintingScript(this.contracts.cip68MintingPolicyCbor)
            .mintRedeemerValue(mintRedeemer)
            .mint(totalFractions.toString(), this.contracts.cip68MintingPolicyId, userTokenName)
            .mintingScript(this.contracts.cip68MintingPolicyCbor)
            .mintRedeemerValue(mintRedeemer)
            // Send reference token to fractionalize script with datum
            .txOut(this.getFractionalizeAddress(), [
            { unit: 'lovelace', quantity: '2000000' },
            {
                unit: this.contracts.cip68MintingPolicyId + referenceTokenName,
                quantity: '1'
            },
        ])
            .txOutInlineDatumValue(propertyDatum)
            // Send user tokens to owner
            .txOut(walletAddress, [
            { unit: 'lovelace', quantity: '2000000' },
            {
                unit: this.contracts.cip68MintingPolicyId + userTokenName,
                quantity: totalFractions.toString()
            },
        ])
            .changeAddress(walletAddress)
            .selectUtxosFrom(await this.provider.fetchAddressUTxOs(walletAddress))
            .complete();
        return unsignedTx;
    }
    /**
     * List fraction tokens for sale on the marketplace
     * @param walletAddress - Seller's wallet address
     * @param fractionPolicyId - Policy ID of the fraction tokens
     * @param fractionAssetName - Asset name of the fraction tokens
     * @param amount - Number of fractions to list
     * @param pricePerFraction - Price per fraction in stablecoin units
     * @param stablecoin - Which stablecoin to accept ('USDM' or 'iUSD')
     */
    async listForSale(walletAddress, fractionPolicyId, fractionAssetName, amount, pricePerFraction, stablecoin = 'USDM') {
        const txBuilder = new core_1.MeshTxBuilder({
            fetcher: this.provider,
            evaluator: this.provider,
        });
        const sellerPkh = (0, core_1.deserializeAddress)(walletAddress).pubKeyHash;
        const stablecoinConfig = exports.STABLECOIN_CONFIG[stablecoin];
        // Build marketplace datum
        const marketplaceDatum = this.buildMarketplaceDatum({
            seller: sellerPkh,
            price: pricePerFraction * amount, // Total price
            stablecoinAsset: {
                policyId: stablecoinConfig.policyId,
                assetName: stablecoinConfig.assetName,
            },
            fractionAsset: {
                policyId: fractionPolicyId,
                assetName: fractionAssetName,
            },
            fractionAmount: amount,
        });
        const unsignedTx = await txBuilder
            // Send fractions to marketplace with datum
            .txOut(this.getMarketplaceAddress(), [
            { unit: 'lovelace', quantity: '2000000' },
            {
                unit: fractionPolicyId + fractionAssetName,
                quantity: amount.toString()
            },
        ])
            .txOutInlineDatumValue(marketplaceDatum)
            .changeAddress(walletAddress)
            .selectUtxosFrom(await this.provider.fetchAddressUTxOs(walletAddress))
            .complete();
        return unsignedTx;
    }
    /**
     * Buy fractions from the marketplace
     * @param buyerAddress - Buyer's wallet address
     * @param listingUtxo - The UTxO containing the listing
     * @param datum - The marketplace datum
     */
    async buyFractions(buyerAddress, listingUtxo, datum) {
        const txBuilder = new core_1.MeshTxBuilder({
            fetcher: this.provider,
            evaluator: this.provider,
        });
        // Buy redeemer (constructor index 0)
        const buyRedeemer = (0, core_1.mConStr0)([]);
        // Fetch the listing UTxO
        const utxos = await this.provider.fetchAddressUTxOs(this.getMarketplaceAddress());
        const listingUtxoData = utxos.find((u) => u.input.txHash === listingUtxo.txHash &&
            u.input.outputIndex === listingUtxo.outputIndex);
        if (!listingUtxoData) {
            throw new Error('Listing UTxO not found');
        }
        const unsignedTx = await txBuilder
            // Spend the marketplace UTxO
            .spendingPlutusScriptV2()
            .txIn(listingUtxo.txHash, listingUtxo.outputIndex)
            .spendingReferenceTxInInlineDatumPresent()
            .spendingReferenceTxInRedeemerValue(buyRedeemer)
            .txInScript(this.contracts.marketplaceScriptCbor)
            // Pay seller the stablecoin amount
            .txOut(datum.seller, [
            { unit: 'lovelace', quantity: '2000000' },
            {
                unit: datum.stablecoinAsset.policyId + datum.stablecoinAsset.assetName,
                quantity: datum.price.toString()
            },
        ])
            // Buyer receives the fractions
            .txOut(buyerAddress, [
            { unit: 'lovelace', quantity: '2000000' },
            {
                unit: datum.fractionAsset.policyId + datum.fractionAsset.assetName,
                quantity: datum.fractionAmount.toString()
            },
        ])
            .changeAddress(buyerAddress)
            .selectUtxosFrom(await this.provider.fetchAddressUTxOs(buyerAddress))
            .complete();
        return unsignedTx;
    }
    /**
     * Cancel a listing (seller only)
     */
    async cancelListing(sellerAddress, listingUtxo) {
        const txBuilder = new core_1.MeshTxBuilder({
            fetcher: this.provider,
            evaluator: this.provider,
        });
        // Cancel redeemer (constructor index 1)
        const cancelRedeemer = (0, core_1.mConStr1)([]);
        const sellerPkh = (0, core_1.deserializeAddress)(sellerAddress).pubKeyHash;
        const unsignedTx = await txBuilder
            .spendingPlutusScriptV2()
            .txIn(listingUtxo.txHash, listingUtxo.outputIndex)
            .spendingReferenceTxInInlineDatumPresent()
            .spendingReferenceTxInRedeemerValue(cancelRedeemer)
            .txInScript(this.contracts.marketplaceScriptCbor)
            .requiredSignerHash(sellerPkh)
            .changeAddress(sellerAddress)
            .selectUtxosFrom(await this.provider.fetchAddressUTxOs(sellerAddress))
            .complete();
        return unsignedTx;
    }
}
exports.PropFiTransactionBuilder = PropFiTransactionBuilder;
// Export singleton instance
exports.propFiTxBuilder = new PropFiTransactionBuilder();
exports.default = PropFiTransactionBuilder;
