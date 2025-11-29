"use strict";
/**
 * Blockfrost API Service for PropFi
 * Cardano blockchain API using Blockfrost
 * https://blockfrost.io/
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.blockfrost = exports.BLOCKFROST_CONFIG = void 0;
exports.fetchMarketplaceListings = fetchMarketplaceListings;
exports.getPropertyDetails = getPropertyDetails;
exports.getWalletTokens = getWalletTokens;
exports.getWalletBalance = getWalletBalance;
exports.getNetworkTip = getNetworkTip;
// Configuration
exports.BLOCKFROST_CONFIG = {
    // Blockfrost endpoints
    mainnet: 'https://cardano-mainnet.blockfrost.io/api/v0',
    preprod: 'https://cardano-preprod.blockfrost.io/api/v0',
    preview: 'https://cardano-preview.blockfrost.io/api/v0',
    // Project ID for authentication
    projectId: 'preprod3EhVdYxWz9oD5XP1TVbbdLxbN4jCNwBe',
};
// Use Preprod for development
const NETWORK = 'preprod';
/**
 * Blockfrost API client
 */
class BlockfrostClient {
    constructor(network = 'preprod') {
        this.baseUrl = exports.BLOCKFROST_CONFIG[network];
        this.projectId = exports.BLOCKFROST_CONFIG.projectId;
    }
    async fetch(endpoint, options) {
        const response = await fetch(`${this.baseUrl}${endpoint}`, {
            headers: {
                'project_id': this.projectId,
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            ...options,
        });
        if (!response.ok) {
            if (response.status === 404) {
                throw new Error(`Resource not found: ${endpoint}`);
            }
            const errorText = await response.text();
            throw new Error(`Blockfrost API error: ${response.status} - ${errorText}`);
        }
        return response.json();
    }
    /**
     * Get the latest epoch information
     * curl -H "project_id: preprod3EhVdYxWz9oD5XP1TVbbdLxbN4jCNwBe" https://cardano-preprod.blockfrost.io/api/v0/epochs/latest
     */
    async getLatestEpoch() {
        return this.fetch('/epochs/latest');
    }
    /**
     * Get the latest block information
     * curl -H "project_id: preprod3EhVdYxWz9oD5XP1TVbbdLxbN4jCNwBe" https://cardano-preprod.blockfrost.io/api/v0/blocks/latest
     */
    async getLatestBlock() {
        return this.fetch('/blocks/latest');
    }
    /**
     * Get list of stake pools
     * curl -H "project_id: preprod3EhVdYxWz9oD5XP1TVbbdLxbN4jCNwBe" https://cardano-preprod.blockfrost.io/api/v0/pools
     */
    async getPools() {
        return this.fetch('/pools');
    }
    /**
     * Get UTxOs at a specific address
     */
    async getAddressUtxos(address) {
        try {
            const response = await this.fetch(`/addresses/${address}/utxos`);
            // Transform Blockfrost response to our UTxO format
            return response.map(utxo => ({
                tx_hash: utxo.tx_hash,
                tx_index: utxo.tx_index || utxo.output_index,
                output_index: utxo.output_index || utxo.tx_index,
                amount: utxo.amount.map((a) => ({
                    unit: a.unit,
                    quantity: a.quantity,
                })),
                block: utxo.block || '',
                data_hash: utxo.data_hash || null,
                inline_datum: utxo.inline_datum || null,
                reference_script_hash: utxo.reference_script_hash || null,
                address: address,
            }));
        }
        catch (error) {
            if (error.message.includes('not found')) {
                return [];
            }
            throw error;
        }
    }
    /**
     * Get UTxOs at a script address containing a specific asset
     */
    async getAddressUtxosWithAsset(address, asset) {
        try {
            const response = await this.fetch(`/addresses/${address}/utxos/${asset}`);
            return response.map(utxo => ({
                tx_hash: utxo.tx_hash,
                tx_index: utxo.tx_index || utxo.output_index,
                output_index: utxo.output_index || utxo.tx_index,
                amount: utxo.amount.map((a) => ({
                    unit: a.unit,
                    quantity: a.quantity,
                })),
                block: utxo.block || '',
                data_hash: utxo.data_hash || null,
                inline_datum: utxo.inline_datum || null,
                reference_script_hash: utxo.reference_script_hash || null,
                address: address,
            }));
        }
        catch (error) {
            if (error.message.includes('not found')) {
                return [];
            }
            throw error;
        }
    }
    /**
     * Get asset information
     */
    async getAssetInfo(asset) {
        try {
            return await this.fetch(`/assets/${asset}`);
        }
        catch (error) {
            console.error('Error fetching asset info:', error);
            return null;
        }
    }
    /**
     * Get asset metadata (CIP-25/CIP-68)
     */
    async getAssetMetadata(policyId, assetName) {
        try {
            const asset = policyId + assetName;
            const assetInfo = await this.getAssetInfo(asset);
            if (!assetInfo)
                return null;
            // Get metadata from onchain_metadata (CIP-25) or metadata
            const metadata = assetInfo.onchain_metadata || assetInfo.metadata;
            if (metadata) {
                return {
                    name: metadata.name || assetInfo.asset_name || 'Unknown Property',
                    description: metadata.description || '',
                    image: metadata.image || metadata.logo || '',
                    mediaType: metadata.mediaType,
                    location: metadata.location,
                    totalValue: metadata.total_value || metadata.totalValue,
                    totalFractions: metadata.total_fractions || metadata.totalFractions,
                    pricePerFraction: metadata.price_per_fraction || metadata.pricePerFraction,
                    legalDocumentCID: metadata.legal_document || metadata.legalDocumentCID,
                };
            }
            return null;
        }
        catch (error) {
            console.error('Error fetching asset metadata:', error);
            return null;
        }
    }
    /**
     * Get specific UTxO by tx hash and index
     */
    async getUtxo(txHash, outputIndex) {
        try {
            const response = await this.fetch(`/txs/${txHash}/utxos`);
            if (!response || !response.outputs)
                return null;
            const output = response.outputs.find((o) => o.output_index === outputIndex);
            if (!output)
                return null;
            return {
                tx_hash: txHash,
                tx_index: outputIndex,
                output_index: outputIndex,
                amount: output.amount.map((a) => ({
                    unit: a.unit,
                    quantity: a.quantity,
                })),
                block: response.block || '',
                data_hash: output.data_hash || null,
                inline_datum: output.inline_datum || null,
                reference_script_hash: output.reference_script_hash || null,
                address: output.address || '',
            };
        }
        catch (error) {
            console.error('Error fetching UTxO:', error);
            return null;
        }
    }
    /**
     * Get transaction details
     */
    async getTransaction(txHash) {
        try {
            return await this.fetch(`/txs/${txHash}`);
        }
        catch (error) {
            console.error('Error fetching transaction:', error);
            return null;
        }
    }
    /**
     * Submit a signed transaction
     */
    async submitTransaction(txCbor) {
        const response = await fetch(`${this.baseUrl}/tx/submit`, {
            method: 'POST',
            headers: {
                'project_id': this.projectId,
                'Content-Type': 'application/cbor',
            },
            body: Buffer.from(txCbor, 'hex'),
        });
        if (!response.ok) {
            const error = await response.text();
            throw new Error(`Transaction submission failed: ${error}`);
        }
        return response.text(); // Returns tx hash
    }
    /**
     * Get protocol parameters (for fee calculation)
     */
    async getProtocolParameters() {
        const epoch = await this.getLatestEpoch();
        return this.fetch(`/epochs/${epoch.epoch}/parameters`);
    }
    /**
     * Get tip (latest block info)
     */
    async getTip() {
        return this.getLatestBlock();
    }
    /**
     * Get datum by hash
     */
    async getDatum(datumHash) {
        try {
            const response = await this.fetch(`/scripts/datum/${datumHash}`);
            return response?.json_value || null;
        }
        catch (error) {
            console.error('Error fetching datum:', error);
            return null;
        }
    }
    /**
     * Get address info (balance, stake, etc.)
     */
    async getAddressInfo(address) {
        try {
            return await this.fetch(`/addresses/${address}`);
        }
        catch (error) {
            console.error('Error fetching address info:', error);
            return null;
        }
    }
    /**
     * Get all assets for an address
     */
    async getAddressAssets(address) {
        try {
            return await this.fetch(`/addresses/${address}/assets`);
        }
        catch (error) {
            console.error('Error fetching address assets:', error);
            return [];
        }
    }
}
// Singleton instance
exports.blockfrost = new BlockfrostClient(NETWORK);
/**
 * PropFi-specific service functions
 */
/**
 * Fetch all marketplace listings from the marketplace script address
 */
async function fetchMarketplaceListings(marketplaceScriptAddress, cip68MintingPolicyId) {
    const utxos = await exports.blockfrost.getAddressUtxos(marketplaceScriptAddress);
    const listings = [];
    for (const utxo of utxos) {
        // Find fraction tokens in this UTxO
        for (const asset of utxo.amount) {
            if (asset.unit === 'lovelace')
                continue;
            const policyId = asset.unit.slice(0, 56);
            const assetName = asset.unit.slice(56);
            // Check if this is a CIP-68 user token (prefix 000de140)
            if (assetName.startsWith('000de140')) {
                // Get metadata from the reference token
                const refAssetName = '000643b0' + assetName.slice(8);
                const metadata = await exports.blockfrost.getAssetMetadata(policyId, refAssetName);
                // Parse inline datum if available
                let datum = null;
                if (utxo.inline_datum) {
                    try {
                        datum = parseMarketplaceDatum(utxo.inline_datum);
                    }
                    catch (e) {
                        console.error('Error parsing datum:', e);
                    }
                }
                if (metadata && datum) {
                    listings.push({
                        utxo,
                        policyId,
                        assetName,
                        metadata,
                        datum,
                    });
                }
            }
        }
    }
    return listings;
}
/**
 * Parse marketplace datum from CBOR/JSON
 * Datum structure: { seller, price, stablecoin_asset, fraction_asset, fraction_amount }
 */
function parseMarketplaceDatum(inlineDatum) {
    // Blockfrost returns inline datums as JSON objects
    // Parse based on the datum structure defined in types.ak
    if (typeof inlineDatum === 'object' && inlineDatum !== null) {
        // Try to extract fields from the datum
        const fields = inlineDatum.fields || inlineDatum;
        return {
            seller: fields[0]?.bytes || fields.seller || '',
            price: parseInt(fields[1]?.int || fields.price || '0'),
            stablecoinPolicyId: fields[2]?.bytes || '',
            stablecoinAssetName: fields[3]?.bytes || '',
            fractionAmount: parseInt(fields[4]?.int || fields.fraction_amount || '0'),
        };
    }
    // Fallback
    console.log('Parsing datum:', inlineDatum);
    return {
        seller: '',
        price: 0,
        stablecoinPolicyId: '',
        stablecoinAssetName: '',
        fractionAmount: 0,
    };
}
/**
 * Get property details by policy ID
 */
async function getPropertyDetails(policyId, propertyId) {
    // Reference token has CIP-68 label 100 (000643b0)
    const refAssetName = '000643b0' + propertyId;
    return exports.blockfrost.getAssetMetadata(policyId, refAssetName);
}
/**
 * Check if a wallet has specific tokens
 */
async function getWalletTokens(walletAddress, policyId) {
    const utxos = await exports.blockfrost.getAddressUtxos(walletAddress);
    const tokens = [];
    for (const utxo of utxos) {
        for (const asset of utxo.amount) {
            if (asset.unit === 'lovelace')
                continue;
            if (!policyId || asset.unit.startsWith(policyId)) {
                // Check if we already have this token
                const existing = tokens.find(t => t.unit === asset.unit);
                if (existing) {
                    existing.quantity = (BigInt(existing.quantity) + BigInt(asset.quantity)).toString();
                }
                else {
                    tokens.push({ ...asset });
                }
            }
        }
    }
    return tokens;
}
/**
 * Get wallet's ADA balance
 */
async function getWalletBalance(walletAddress) {
    const utxos = await exports.blockfrost.getAddressUtxos(walletAddress);
    let balance = 0n;
    for (const utxo of utxos) {
        const lovelace = utxo.amount.find(a => a.unit === 'lovelace');
        if (lovelace) {
            balance += BigInt(lovelace.quantity);
        }
    }
    return balance;
}
/**
 * Get current network tip
 */
async function getNetworkTip() {
    const block = await exports.blockfrost.getLatestBlock();
    return {
        slot: block.slot,
        block: block.height,
        epoch: block.epoch,
    };
}
exports.default = exports.blockfrost;
