/**
 * PropFi Offchain SDK
 * Main entry point for all offchain functionality
 */

// Transaction Builder
export {
  PropFiTransactionBuilder,
  propFiTxBuilder,
  STABLECOIN_CONFIG,
  CIP68_REFERENCE_LABEL,
  CIP68_USER_TOKEN_LABEL,
  NETWORK,
  BLOCKFROST_CONFIG,
  loadContracts,
} from './transaction_builder';

export type {
  PropertyMetadata,
  PropertyDatum,
  MarketplaceDatum,
  ContractConfig,
} from './transaction_builder';

// Blockfrost Service
export {
  blockfrost,
  BLOCKFROST_CONFIG as BLOCKFROST_API_CONFIG,
  fetchMarketplaceListings,
  getPropertyDetails,
  getWalletTokens,
  getWalletBalance,
  getNetworkTip,
} from './blockfrost';

export type {
  Asset,
  UTxO,
  AssetMetadata,
  MarketplaceListing,
} from './blockfrost';

// Deployment
export {
  loadCompiledContracts,
  generateContractConfig,
  exportContractConfig,
  displayContractInfo,
} from './deploy';
