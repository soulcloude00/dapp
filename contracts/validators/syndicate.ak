use aiken/collection/list
use aiken/interval.{Finite}
use cardano/address.{VerificationKey}
use cardano/assets
use cardano/transaction.{Output, OutputReference, Transaction}
use propfi/types.{Deposit, EscrowDatum, EscrowRedeemer, Finalize, Refund}

validator syndicate_escrow {
  spend(
    opt_datum: Option<EscrowDatum>,
    redeemer: EscrowRedeemer,
    _ref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(datum) = opt_datum

    when redeemer is {
      Deposit -> check_deposit(datum, tx)
      Finalize -> check_finalize(datum, tx)
      Refund -> check_refund(datum, tx)
    }
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

fn check_deposit(datum: EscrowDatum, tx: Transaction) -> Bool {
  // In a real implementation, we would verify:
  // 1. The output back to the script has the same datum structure but with the new investor added.
  // 2. The value of the output has increased by the deposit amount.
  // For MVP/Hackathon, we'll assume the off-chain code constructs this correctly and just check
  // that the script output exists.
  
  let script_output_exists =
    list.any(
      tx.outputs,
      fn(output) {
        // Check if output is to the same script address (simplified check)
        // Ideally we check the credential, but for now we check if it holds the stablecoin
        assets.quantity_of(
          output.value,
          datum.stablecoin_asset.policy_id,
          datum.stablecoin_asset.asset_name,
        ) > 0
      },
    )
    
  script_output_exists
}

fn check_finalize(datum: EscrowDatum, tx: Transaction) -> Bool {
  // 1. Verify Target Met
  // Ideally we check the input value, but we can also check if the output to seller is sufficient.
  
  let seller_paid =
    list.any(
      tx.outputs,
      fn(output) {
        when output.address.payment_credential is {
          VerificationKey(pkh) -> {
            let amount =
              assets.quantity_of(
                output.value,
                datum.stablecoin_asset.policy_id,
                datum.stablecoin_asset.asset_name,
              )
            pkh == datum.seller && amount >= datum.target
          }
          _ -> False
        }
      },
    )

  seller_paid
}

fn check_refund(datum: EscrowDatum, tx: Transaction) -> Bool {
  // 1. Verify Deadline Passed
  let deadline_passed =
    when tx.validity_range.lower_bound.bound_type is {
      Finite(now) -> now > datum.deadline
      _ -> False
    }

  deadline_passed
}
