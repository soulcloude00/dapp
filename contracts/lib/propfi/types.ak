use aiken/crypto.{VerificationKeyHash}

pub type POSIXTime =
  Int

pub type AssetClass {
  policy_id: ByteArray,
  asset_name: ByteArray,
}

// CIP-68 Token Prefixes
// Reference Token (100): 000643b0
// User Token (222): 000de140
pub const cip68_reference_label: ByteArray = #"000643b0"
pub const cip68_user_token_label: ByteArray = #"000de140"

pub type PropertyMetadata {
  name: ByteArray,
  description: ByteArray,
  location: ByteArray,
  total_value: Int,
  total_fractions: Int,
}

pub type PropertyDatum {
  owner: VerificationKeyHash,
  price: Int,
  fraction_token: AssetClass,
  total_fractions: Int,
  metadata: PropertyMetadata,
}

pub type FractionalizeRedeemer {
  MintFractions
  BurnFractions
  UnlockProperty
}

pub type MintRedeemer {
  MintProperty { property_id: ByteArray }
  BurnProperty { property_id: ByteArray }
}

pub type MarketplaceDatum {
  seller: VerificationKeyHash,
  price: Int,
  stablecoin_asset: AssetClass,
  fraction_asset: AssetClass,
  fraction_amount: Int,
}

pub type MarketplaceRedeemer {
  Buy
  Cancel
}

// Placeholder Policy IDs for Stablecoins on Preprod
// IMPORTANT: Replace these with actual Policy IDs when deploying
pub const usdm_policy_id: ByteArray = #"c48cbb3d5e57ed56e276bc45f99ab39abe94e6cd7ac39fb402da47ad"
pub const usdm_asset_name: ByteArray = #"5553444d"  // "USDM" in hex

pub const iusd_policy_id: ByteArray = #"f66d78b4a3cb3d37afa0ec36461e51ecbde00f26c8f0a68f94b69880"
pub const iusd_asset_name: ByteArray = #"69555344"  // "iUSD" in hex
