use aiken/primitive/bytearray
use aiken/crypto.{VerificationKeyHash}
use aiken/collection/list
use cardano/transaction.{InlineDatum, Output, OutputReference, Transaction}
use cardano/address.{Script, VerificationKey}
use cardano/assets
use propfi/types.{
  BurnFractions, BurnProperty, Buy, Cancel, FractionalizeRedeemer,
  MarketplaceDatum, MarketplaceRedeemer, MintFractions, MintProperty,
  MintRedeemer, PropertyDatum, UnlockProperty,
}

// =============================================================================
// Constants
// =============================================================================

const reference_token_prefix: ByteArray = #"000643b0"
const user_token_prefix: ByteArray = #"000de140"

// =============================================================================
// Validator 1: Fractionalize
// =============================================================================

validator fractionalize {
  // v1.1 Change: Added `_ref` (OutputReference) and replaced `ctx` with `tx` (Transaction)
  spend(
    opt_datum: Option<PropertyDatum>,
    redeemer: FractionalizeRedeemer,
    _ref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(datum) = opt_datum
    trace @"Fractionalize validator executing"

    when redeemer is {
      MintFractions -> {
        // tx.mint is a Value in v2.x stdlib
        let fraction_asset = datum.fraction_token

        let amount_minted =
          assets.quantity_of(
            tx.mint,
            fraction_asset.policy_id,
            fraction_asset.asset_name,
          )

        amount_minted == datum.total_fractions
      }
      BurnFractions -> check_owner_signed(datum.owner, tx)
      UnlockProperty -> check_owner_signed(datum.owner, tx)
    }
  }
}

// =============================================================================
// Validator 2: CIP-68 Minting Policy
// =============================================================================

validator cip68_minting {
  // Mint validators receive policy_id and transaction directly in v1.1+
  mint(redeemer: MintRedeemer, policy_id: ByteArray, tx: Transaction) {
    when redeemer is {
      MintProperty { property_id } -> {
        let reference_token_name =
          bytearray.concat(reference_token_prefix, property_id)
        let user_token_name = bytearray.concat(user_token_prefix, property_id)

        // Use quantity_of with full Value
        let ref_token_count =
          assets.quantity_of(tx.mint, policy_id, reference_token_name)

        let user_token_count =
          assets.quantity_of(tx.mint, policy_id, user_token_name)

        let has_reference_output =
          list.any(
            tx.outputs,
            fn(output) {
              when output.address.payment_credential is {
                Script(_) -> {
                  let has_ref =
                    assets.quantity_of(
                      output.value,
                      policy_id,
                      reference_token_name,
                    ) == 1
                  has_ref && has_valid_datum(output)
                }
                _ -> False
              }
            },
          )

        ref_token_count == 1 && user_token_count > 0 && has_reference_output
      }

      BurnProperty { property_id } -> {
        let reference_token_name =
          bytearray.concat(reference_token_prefix, property_id)
        let user_token_name = bytearray.concat(user_token_prefix, property_id)

        let ref_token_count =
          assets.quantity_of(tx.mint, policy_id, reference_token_name)
        let user_token_count =
          assets.quantity_of(tx.mint, policy_id, user_token_name)

        ref_token_count <= 0 && user_token_count <= 0
      }
    }
  }
}

// =============================================================================
// Validator 3: Marketplace Validator
// =============================================================================

validator marketplace {
  // Spend validators receive output_ref and transaction directly in v1.1+
  spend(
    opt_datum: Option<MarketplaceDatum>,
    redeemer: MarketplaceRedeemer,
    _ref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(datum) = opt_datum
    trace @"Marketplace validator executing"

    when redeemer is {
      Buy -> check_buy(datum, tx)
      Cancel -> check_cancel(datum, tx)
    }
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

fn check_owner_signed(owner: VerificationKeyHash, tx: Transaction) -> Bool {
  list.has(tx.extra_signatories, owner)
}

fn has_valid_datum(output: Output) -> Bool {
  when output.datum is {
    InlineDatum(_) -> True
    _ -> False
  }
}

fn check_buy(datum: MarketplaceDatum, tx: Transaction) -> Bool {
  let seller_paid =
    list.any(
      tx.outputs,
      fn(output) {
        when output.address.payment_credential is {
          VerificationKey(pkh) -> {
            let stablecoin_amount =
              assets.quantity_of(
                output.value,
                datum.stablecoin_asset.policy_id,
                datum.stablecoin_asset.asset_name,
              )
            pkh == datum.seller && stablecoin_amount >= datum.price
          }
          _ -> False
        }
      },
    )

  trace @"Checking seller payment"
  seller_paid
}

fn check_cancel(datum: MarketplaceDatum, tx: Transaction) -> Bool {
  trace @"Checking cancel authorization"
  list.has(tx.extra_signatories, datum.seller)
}