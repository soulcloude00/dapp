/**
 * Blockfrost API Service for PropFi
 * Cardano blockchain API using Blockfrost
 * https://blockfrost.io/
 */

// Configuration
export const BLOCKFROST_CONFIG = {
  // Blockfrost endpoints
  mainnet: 'https://cardano-mainnet.blockfrost.io/api/v0',
  preprod: 'https://cardano-preprod.blockfrost.io/api/v0',
  preview: 'https://cardano-preview.blockfrost.io/api/v0',
  // Project ID for authentication
  projectId: 'preprod3EhVdYxWz9oD5XP1TVbbdLxbN4jCNwBe',
};

// Use Preprod for development
const NETWORK: keyof Omit<typeof BLOCKFROST_CONFIG, 'projectId'> = 'preprod';

// Types
export interface Asset {
  unit: string;
  quantity: string;
}

export interface UTxO {
  tx_hash: string;
  tx_index: number;
  output_index: number;
  amount: Asset[];
  block: string;
  data_hash: string | null;
  inline_datum: any | null;
  reference_script_hash: string | null;
  address: string;
}

export interface AssetMetadata {
  name: string;
  description: string;
  image: string;
  mediaType?: string;
  // PropFi specific fields
  location?: string;
  totalValue?: number;
  totalFractions?: number;
  pricePerFraction?: number;
  legalDocumentCID?: string;
}

export interface MarketplaceListing {
  utxo: UTxO;
  policyId: string;
  assetName: string;
  metadata: AssetMetadata;
  datum: {
    seller: string;
    price: number;
    stablecoinPolicyId: string;
    stablecoinAssetName: string;
    fractionAmount: number;
  };
}

/**
 * Blockfrost API client
 */
class BlockfrostClient {
  private baseUrl: string;
  private projectId: string;

  constructor(network: keyof Omit<typeof BLOCKFROST_CONFIG, 'projectId'> = 'preprod') {
    this.baseUrl = BLOCKFROST_CONFIG[network];
    this.projectId = BLOCKFROST_CONFIG.projectId;
  }

  private async fetch<T>(endpoint: string, options?: RequestInit): Promise<T> {
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
  async getLatestEpoch(): Promise<any> {
    return this.fetch<any>('/epochs/latest');
  }

  /**
   * Get the latest block information
   * curl -H "project_id: preprod3EhVdYxWz9oD5XP1TVbbdLxbN4jCNwBe" https://cardano-preprod.blockfrost.io/api/v0/blocks/latest
   */
  async getLatestBlock(): Promise<any> {
    return this.fetch<any>('/blocks/latest');
  }

  /**
   * Get list of stake pools
   * curl -H "project_id: preprod3EhVdYxWz9oD5XP1TVbbdLxbN4jCNwBe" https://cardano-preprod.blockfrost.io/api/v0/pools
   */
  async getPools(): Promise<string[]> {
    return this.fetch<string[]>('/pools');
  }

  /**
   * Get UTxOs at a specific address
   */
  async getAddressUtxos(address: string): Promise<UTxO[]> {
    try {
      const response = await this.fetch<any[]>(`/addresses/${address}/utxos`);

      // Transform Blockfrost response to our UTxO format
      return response.map(utxo => ({
        tx_hash: utxo.tx_hash,
        tx_index: utxo.tx_index || utxo.output_index,
        output_index: utxo.output_index || utxo.tx_index,
        amount: utxo.amount.map((a: any) => ({
          unit: a.unit,
          quantity: a.quantity,
        })),
        block: utxo.block || '',
        data_hash: utxo.data_hash || null,
        inline_datum: utxo.inline_datum || null,
        reference_script_hash: utxo.reference_script_hash || null,
        address: address,
      }));
    } catch (error) {
      if ((error as Error).message.includes('not found')) {
        return [];
      }
      throw error;
    }
  }

  /**
   * Get UTxOs at a script address containing a specific asset
   */
  async getAddressUtxosWithAsset(address: string, asset: string): Promise<UTxO[]> {
    try {
      const response = await this.fetch<any[]>(`/addresses/${address}/utxos/${asset}`);

      return response.map(utxo => ({
        tx_hash: utxo.tx_hash,
        tx_index: utxo.tx_index || utxo.output_index,
        output_index: utxo.output_index || utxo.tx_index,
        amount: utxo.amount.map((a: any) => ({
          unit: a.unit,
          quantity: a.quantity,
        })),
        block: utxo.block || '',
        data_hash: utxo.data_hash || null,
        inline_datum: utxo.inline_datum || null,
        reference_script_hash: utxo.reference_script_hash || null,
        address: address,
      }));
    } catch (error) {
      if ((error as Error).message.includes('not found')) {
        return [];
      }
      throw error;
    }
  }

  /**
   * Get asset information
   */
  async getAssetInfo(asset: string): Promise<any> {
    try {
      return await this.fetch<any>(`/assets/${asset}`);
    } catch (error) {
      console.error('Error fetching asset info:', error);
      return null;
    }
  }

  /**
   * Get asset metadata (CIP-25/CIP-68)
   */
  async getAssetMetadata(policyId: string, assetName: string): Promise<AssetMetadata | null> {
    try {
      const asset = policyId + assetName;
      const assetInfo = await this.getAssetInfo(asset);

      if (!assetInfo) return null;

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
    } catch (error) {
      console.error('Error fetching asset metadata:', error);
      return null;
    }
  }

  /**
   * Get specific UTxO by tx hash and index
   */
  async getUtxo(txHash: string, outputIndex: number): Promise<UTxO | null> {
    try {
      const response = await this.fetch<any>(`/txs/${txHash}/utxos`);

      if (!response || !response.outputs) return null;

      const output = response.outputs.find((o: any) => o.output_index === outputIndex);

      if (!output) return null;

      return {
        tx_hash: txHash,
        tx_index: outputIndex,
        output_index: outputIndex,
        amount: output.amount.map((a: any) => ({
          unit: a.unit,
          quantity: a.quantity,
        })),
        block: response.block || '',
        data_hash: output.data_hash || null,
        inline_datum: output.inline_datum || null,
        reference_script_hash: output.reference_script_hash || null,
        address: output.address || '',
      };
    } catch (error) {
      console.error('Error fetching UTxO:', error);
      return null;
    }
  }

  /**
   * Get transaction details
   */
  async getTransaction(txHash: string): Promise<any> {
    try {
      return await this.fetch<any>(`/txs/${txHash}`);
    } catch (error) {
      console.error('Error fetching transaction:', error);
      return null;
    }
  }

  /**
   * Submit a signed transaction
   */
  async submitTransaction(txCbor: string): Promise<string> {
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
  async getProtocolParameters(): Promise<any> {
    const epoch = await this.getLatestEpoch();
    return this.fetch<any>(`/epochs/${epoch.epoch}/parameters`);
  }

  /**
   * Get tip (latest block info)
   */
  async getTip(): Promise<any> {
    return this.getLatestBlock();
  }

  /**
   * Get datum by hash
   */
  async getDatum(datumHash: string): Promise<any> {
    try {
      const response = await this.fetch<any>(`/scripts/datum/${datumHash}`);
      return response?.json_value || null;
    } catch (error) {
      console.error('Error fetching datum:', error);
      return null;
    }
  }

  /**
   * Get address info (balance, stake, etc.)
   */
  async getAddressInfo(address: string): Promise<any> {
    try {
      return await this.fetch<any>(`/addresses/${address}`);
    } catch (error) {
      console.error('Error fetching address info:', error);
      return null;
    }
  }

  /**
   * Get all assets for an address
   */
  async getAddressAssets(address: string): Promise<any[]> {
    try {
      return await this.fetch<any[]>(`/addresses/${address}/assets`);
    } catch (error) {
      console.error('Error fetching address assets:', error);
      return [];
    }
  }
}

// Singleton instance
export const blockfrost = new BlockfrostClient(NETWORK);

/**
 * PropFi-specific service functions
 */

/**
 * Fetch all marketplace listings from the marketplace script address
 */
export async function fetchMarketplaceListings(
  marketplaceScriptAddress: string,
  cip68MintingPolicyId: string
): Promise<MarketplaceListing[]> {
  const utxos = await blockfrost.getAddressUtxos(marketplaceScriptAddress);
  const listings: MarketplaceListing[] = [];

  for (const utxo of utxos) {
    // Find fraction tokens in this UTxO
    for (const asset of utxo.amount) {
      if (asset.unit === 'lovelace') continue;

      const policyId = asset.unit.slice(0, 56);
      const assetName = asset.unit.slice(56);

      // Check if this is a CIP-68 user token (prefix 000de140)
      if (assetName.startsWith('000de140')) {
        // Get metadata from the reference token
        const refAssetName = '000643b0' + assetName.slice(8);
        const metadata = await blockfrost.getAssetMetadata(policyId, refAssetName);

        // Parse inline datum if available
        let datum = null;
        if (utxo.inline_datum) {
          try {
            datum = parseMarketplaceDatum(utxo.inline_datum);
          } catch (e) {
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
function parseMarketplaceDatum(inlineDatum: any): MarketplaceListing['datum'] {
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
export async function getPropertyDetails(
  policyId: string,
  propertyId: string
): Promise<AssetMetadata | null> {
  // Reference token has CIP-68 label 100 (000643b0)
  const refAssetName = '000643b0' + propertyId;
  return blockfrost.getAssetMetadata(policyId, refAssetName);
}

/**
 * Check if a wallet has specific tokens
 */
export async function getWalletTokens(
  walletAddress: string,
  policyId?: string
): Promise<Asset[]> {
  const utxos = await blockfrost.getAddressUtxos(walletAddress);
  const tokens: Asset[] = [];

  for (const utxo of utxos) {
    for (const asset of utxo.amount) {
      if (asset.unit === 'lovelace') continue;

      if (!policyId || asset.unit.startsWith(policyId)) {
        // Check if we already have this token
        const existing = tokens.find(t => t.unit === asset.unit);
        if (existing) {
          existing.quantity = (BigInt(existing.quantity) + BigInt(asset.quantity)).toString();
        } else {
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
export async function getWalletBalance(walletAddress: string): Promise<bigint> {
  const utxos = await blockfrost.getAddressUtxos(walletAddress);
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
export async function getNetworkTip(): Promise<{ slot: number; block: number; epoch: number }> {
  const block = await blockfrost.getLatestBlock();
  return {
    slot: block.slot,
    block: block.height,
    epoch: block.epoch,
  };
}

export default blockfrost;
