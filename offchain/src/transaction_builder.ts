/**
 * PropFi Transaction Builder
 * Builds Cardano transactions for property fractionalization and marketplace operations
 * Uses MeshJS SDK with Blockfrost Provider
 */

import {
  MeshTxBuilder,
  MeshWallet,
  BlockfrostProvider,  // Using Blockfrost API
  resolveScriptHash,
  serializePlutusScript,
  deserializeAddress,
  serializeAddressObj,
  mConStr0,
  mConStr1,
  stringToHex,
  hexToString,
} from '@meshsdk/core';

import * as fs from 'fs';
import * as path from 'path';

// ============================================================================
// Configuration
// ============================================================================

export const NETWORK = 'preprod';

// Blockfrost configuration
export const BLOCKFROST_CONFIG = {
  network: NETWORK as 'preprod' | 'preview' | 'mainnet',
  projectId: 'preprod3EhVdYxWz9oD5XP1TVbbdLxbN4jCNwBe',
};

// Stablecoin configuration for Preprod testnet
export const STABLECOIN_CONFIG = {
  USDM: {
    policyId: 'c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad',
    assetName: stringToHex('USDM'),
    decimals: 6,
  },
  iUSD: {
    policyId: 'f66d78b4a3cb3d37afa0ec36461e51ecbde00f26c8f0a68f94b69880',
    assetName: stringToHex('iUSD'),
    decimals: 6,
  },
};

// CIP-68 Token Labels
export const CIP68_REFERENCE_LABEL = '000643b0'; // (100) Reference Token
export const CIP68_USER_TOKEN_LABEL = '000de140'; // (222) User/Fraction Token

// ============================================================================
// Types
// ============================================================================

export interface PropertyMetadata {
  name: string;
  description: string;
  image: string; // IPFS CID or URL
  location: string;
  totalValue: number; // in stablecoin units
  totalFractions: number;
  pricePerFraction: number;
  legalDocumentCID?: string; // IPFS CID for legal documents
}

export interface PropertyDatum {
  owner: string; // PubKeyHash
  price: number;
  fractionToken: {
    policyId: string;
    assetName: string;
  };
  totalFractions: number;
  metadata: PropertyMetadata;
}

export interface MarketplaceDatum {
  seller: string; // PubKeyHash
  price: number; // Price per fraction in stablecoin
  stablecoinAsset: {
    policyId: string;
    assetName: string;
  };
  fractionAsset: {
    policyId: string;
    assetName: string;
  };
  fractionAmount: number;
}

export interface ContractConfig {
  fractionalizeScriptHash: string;
  fractionalizeScriptCbor: string;
  cip68MintingPolicyId: string;
  cip68MintingPolicyCbor: string;
  marketplaceScriptHash: string;
  marketplaceScriptCbor: string;
}

// ============================================================================
// Contract Loading
// ============================================================================

let contractConfig: ContractConfig | null = null;

/**
 * Load contract configuration from plutus.json
 */
export function loadContracts(): ContractConfig {
  if (contractConfig) return contractConfig;

  const plutusJsonPath = path.join(__dirname, '../../contracts/plutus.json');

  if (!fs.existsSync(plutusJsonPath)) {
    throw new Error('plutus.json not found. Run `aiken build` first.');
  }

  const plutusJson = JSON.parse(fs.readFileSync(plutusJsonPath, 'utf-8'));

  const getValidator = (title: string) => {
    const v = plutusJson.validators.find((v: any) => v.title === title);
    if (!v) throw new Error(`Validator ${title} not found`);
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

export class PropFiTransactionBuilder {
  private provider: BlockfrostProvider;
  private contracts: ContractConfig;

  constructor() {
    // Using Blockfrost API
    this.provider = new BlockfrostProvider(BLOCKFROST_CONFIG.projectId);
    this.contracts = loadContracts();
  }

  /**
   * Get the marketplace script address
   */
  getMarketplaceAddress(): string {
    // Generate address from script hash
    const scriptHash = this.contracts.marketplaceScriptHash;
    // For testnet, use network ID 0
    return `addr_test1wz${scriptHash}`; // Simplified - use proper encoding in production
  }

  /**
   * Get the fractionalize script address
   */
  getFractionalizeAddress(): string {
    const scriptHash = this.contracts.fractionalizeScriptHash;
    return `addr_test1wz${scriptHash}`; // Simplified - use proper encoding in production
  }

  /**
   * Build CIP-68 Reference Token Datum
   */
  buildReferenceDatum(metadata: PropertyMetadata): object {
    // CIP-68 reference datum structure
    return mConStr0([
      // Metadata map - all values as strings/hex
      new Map<string, string | number>([
        [stringToHex('name'), stringToHex(metadata.name)],
        [stringToHex('description'), stringToHex(metadata.description)],
        [stringToHex('image'), stringToHex(metadata.image)],
        [stringToHex('location'), stringToHex(metadata.location)],
        [stringToHex('total_value'), metadata.totalValue],
        [stringToHex('total_fractions'), metadata.totalFractions],
        [stringToHex('price_per_fraction'), metadata.pricePerFraction],
      ]),
      1, // Version
    ]);
  }

  /**
   * Build Property Datum for fractionalize validator
   */
  buildPropertyDatum(datum: PropertyDatum): object {
    return mConStr0([
      datum.owner,
      datum.price,
      mConStr0([datum.fractionToken.policyId, datum.fractionToken.assetName]),
      datum.totalFractions,
      mConStr0([
        stringToHex(datum.metadata.name),
        stringToHex(datum.metadata.description),
        stringToHex(datum.metadata.location),
        datum.metadata.totalValue,
        datum.metadata.totalFractions,
      ]),
    ]);
  }

  /**
   * Build Marketplace Datum
   */
  buildMarketplaceDatum(datum: MarketplaceDatum): object {
    return mConStr0([
      datum.seller,
      datum.price,
      mConStr0([datum.stablecoinAsset.policyId, datum.stablecoinAsset.assetName]),
      mConStr0([datum.fractionAsset.policyId, datum.fractionAsset.assetName]),
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
  async fractionalizeProperty(
    walletAddress: string,
    propertyId: string,
    metadata: PropertyMetadata,
    totalFractions: number
  ): Promise<string> {
    const txBuilder = new MeshTxBuilder({
      fetcher: this.provider,
      evaluator: this.provider,
    });

    // Build token names with CIP-68 prefixes
    const referenceTokenName = CIP68_REFERENCE_LABEL + propertyId;
    const userTokenName = CIP68_USER_TOKEN_LABEL + propertyId;

    // Get owner's pubkey hash
    const ownerPkh = deserializeAddress(walletAddress).pubKeyHash;

    // Build the minting redeemer (MintProperty { property_id })
    const mintRedeemer = mConStr0([propertyId]);

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
  async listForSale(
    walletAddress: string,
    fractionPolicyId: string,
    fractionAssetName: string,
    amount: number,
    pricePerFraction: number,
    stablecoin: 'USDM' | 'iUSD' = 'USDM'
  ): Promise<string> {
    const txBuilder = new MeshTxBuilder({
      fetcher: this.provider,
      evaluator: this.provider,
    });

    const sellerPkh = deserializeAddress(walletAddress).pubKeyHash;
    const stablecoinConfig = STABLECOIN_CONFIG[stablecoin];

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
  async buyFractions(
    buyerAddress: string,
    listingUtxo: { txHash: string; outputIndex: number },
    datum: MarketplaceDatum
  ): Promise<string> {
    const txBuilder = new MeshTxBuilder({
      fetcher: this.provider,
      evaluator: this.provider,
    });

    // Buy redeemer (constructor index 0)
    const buyRedeemer = mConStr0([]);

    // Fetch the listing UTxO
    const utxos = await this.provider.fetchAddressUTxOs(this.getMarketplaceAddress());
    const listingUtxoData = utxos.find(
      (u: any) => u.input.txHash === listingUtxo.txHash &&
        u.input.outputIndex === listingUtxo.outputIndex
    );

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
  async cancelListing(
    sellerAddress: string,
    listingUtxo: { txHash: string; outputIndex: number }
  ): Promise<string> {
    const txBuilder = new MeshTxBuilder({
      fetcher: this.provider,
      evaluator: this.provider,
    });

    // Cancel redeemer (constructor index 1)
    const cancelRedeemer = mConStr1([]);

    const sellerPkh = deserializeAddress(sellerAddress).pubKeyHash;

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

// Export singleton instance
export const propFiTxBuilder = new PropFiTransactionBuilder();

export default PropFiTransactionBuilder;
