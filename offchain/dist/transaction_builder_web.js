"use strict";
/**
 * PropFi Transaction Builder (Web Version)
 * Builds Cardano transactions for property fractionalization and marketplace operations
 * Uses MeshJS SDK with Blockfrost Provider
 * Browser-compatible: No fs/path imports, hardcoded contract config.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.propFiTxBuilder = exports.PropFiTransactionBuilder = exports.CIP68_USER_TOKEN_LABEL = exports.CIP68_REFERENCE_LABEL = exports.STABLECOIN_CONFIG = exports.BLOCKFROST_CONFIG = exports.NETWORK = void 0;
const core_1 = require("@meshsdk/core");
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
// Contract Configuration (Hardcoded for Web)
// ============================================================================
const CONTRACT_CONFIG = {
    fractionalizeScriptHash: '4e03e3aacbb838b267ee6dcccdaffebff835a3a8cf51d9870e5a6b2e',
    fractionalizeScriptCbor: '59026501010029800aba2aba1aba0aab9faab9eaab9dab9a488888896600264653001300800198041804800cdc3a400530080024888966002600460106ea800e26466453001159800980098059baa0028cc004c03cc030dd5001488c8cc004004dd618091809980998099809980998099809980998079baa0022259800800c528456600266e3cdd718098008024528c4cc008008c05000500e202298059baa00748896600260080031323370f300137566026602860286028602860206ea80226eb8c04cc040dd5000cdd71809980a18081baa0014888c966002601a60266ea80062900044dd6980b980a1baa001404864b3001300d3013375400314c103d87a8000899198008009bab30183015375400444b30010018a6103d87a8000899192cc004cdc8803000c56600266e3c018006266e9520003301a30180024bd7045300103d87a80004059133004004301c00340586eb8c058004c064005017202432330010010042259800800c5300103d87a8000899192cc004cdc8803000c56600266e3c018006266e9520003301930170024bd7045300103d87a80004055133004004301b00340546eb8c054004c0600050160dd69809980a180a180a18081baa004301230133013300f37540071598009804000c4cc008dd7180918079baa0030078998011bae3012300f375400600e806900d22c805260166ea801e601e0069112cc004c01000a2b3001300f37540150038b20208acc004c02000a2b3001300f37540150038b20208acc004cdc3a400800515980098079baa00a801c5901045900d201a4034300d300e001370e900018049baa0038b200e180400098019baa0088a4d13656400401',
    cip68MintingPolicyId: '7af62086280f10305eec66f17afff08526513d5b41549cb63bd1e4ca',
    cip68MintingPolicyCbor: '5902cb01010029800aba2aba1aba0aab9faab9eaab9dab9a488888896600264653001300800198041804800cdc3a400130080024888966002600460106ea800e266446644b30013006001899192cc004c04c00a0091640406eb8c044004c034dd5004456600260060031323259800980980140122c8080dd7180880098069baa0088b2016402c26644b30013006300c375401113232598009802cc004dd5980218079baa0078034005003456600266e21200098009bab3004300f375400f00699b8a488104000de14000002400d13232330010013758600460226ea8024896600200314a1159800992cc004c024c048dd5180b18099baa3016301337540031598009804cc004dd5980b180b98099baa0018054015007456600266e1d200430123754600860266ea800629462941011452820228a504044602a00314a31330020023016001404080988c04cc050c050006294100d4528201a3371491104000643b000001375c6020601a6ea8022264b300133713300137566006601c6ea801a00b33714910104000643b0000014008900044cdc4cc004dd5980198071baa006802ccdc5244104000de140000014008900045282018375c6020601a6ea802100b118079808180818081808000911192cc004c014c038dd5000c5200089bad3012300f37540028068c966002600a601c6ea8006298103d87a8000899198008009bab30133010375400444b30010018a6103d87a8000899192cc004cdc8803000c56600266e3c018006266e9520003301530130024bd7045300103d87a80004045133004004301700340446eb8c044004c050005012201a32330010010042259800800c5300103d87a8000899192cc004cdc8803000c56600266e3c018006266e9520003301430120024bd7045300103d87a80004041133004004301600340406eb8c040004c04c00501118051baa006375c601860126ea800cdc3a400516401c300800130033754011149a26cac8009',
    marketplaceScriptHash: 'a763ffb61095577404d7594b17475e8db0d3b3a2595fa82e93642225',
    marketplaceScriptCbor: '59029301010029800aba2aba1aba0aab9faab9eaab9dab9a488888896600264653001300800198041804800cdc3a400530080024888966002600460106ea800e26466453001159800980098059baa0028992cc004c008c030dd500444cc88c8cc004004dd6180198081baa0082259800800c52845660026464b300130083012375400315980099b8f375c602c60266ea8004dd7180b18099baa007899b89375a600a60266ea801e60026eacc014c04cdd50014dd7180b18099baa30063013375400f375c600a60266ea8c018c04cdd5003a44464b300130103016375400314800226eb4c068c05cdd5000a02a32598009808180b1baa0018a60103d87a8000899198008009bab301b3018375400444b30010018a6103d87a8000899192cc004cdc8803000c56600266e3c018006266e9520003301d301b0024bd7045300103d87a80004065133004004301f00340646eb8c064004c07000501a202a32330010010042259800800c5300103d87a8000899192cc004cdc8803000c56600266e3c018006266e9520003301c301a0024bd7045300103d87a80004061133004004301e00340606eb8c060004c06c0050192294101145282022301530123754602a60246ea8004c0500062946266004004602a00280790121180898091809000918089809000c4c8cc88cc008008004896600200314a115980099b8f375c602600200714a3133002002301400140388088dd618089809180918091809180918091809180918071baa006375c6020601a6ea800500b180798061baa0028b201498059baa0079807801a444b300130040028acc004c03cdd5005400e2c80822b300130080028acc004c03cdd5005400e2c80822c806900d0c034c038004dc3a400060126ea800e2c8038601000260066ea802229344d95900101',
};
// ============================================================================
// Transaction Builder Class
// ============================================================================
class PropFiTransactionBuilder {
    constructor() {
        // Using Blockfrost API
        this.provider = new core_1.BlockfrostProvider(exports.BLOCKFROST_CONFIG.projectId);
        this.contracts = CONTRACT_CONFIG;
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
