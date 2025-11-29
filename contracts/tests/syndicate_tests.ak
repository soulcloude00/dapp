use aiken/interval.{Finite}
use aiken/list
use cardano/address.{VerificationKey}
use cardano/assets.{from_lovelace}
use cardano/transaction.{Output, OutputReference, Transaction, ValidityRange}
use propfi/types.{AssetClass, Deposit, EscrowDatum, EscrowRedeemer, Finalize, Refund}
use validators/syndicate

// =============================================================================
// Mocks & Helpers
// =============================================================================

const mock_policy_id = #"11111111111111111111111111111111111111111111111111111111"
const mock_asset_name = #"5553444d" // USDM

fn mock_datum() -> EscrowDatum {
  EscrowDatum {
    target: 1000,
    deadline: 100,
    investors: [],
    seller: #"00000000000000000000000000000000000000000000000000000001",
    stablecoin_asset: AssetClass {
      policy_id: mock_policy_id,
      asset_name: mock_asset_name,
    },
  }
}

fn mock_tx() -> Transaction {
  transaction.placeholder()
}

fn mock_utxo_ref() -> OutputReference {
  OutputReference { transaction_id: #"00", output_index: 0 }
}

// =============================================================================
// Tests
// =============================================================================

test deposit_success() {
  let datum = mock_datum()
  let redeemer = Deposit
  
  // Mock output back to script with stablecoin
  let script_output = Output {
    address: address.from_script(#"00"), // Simplified
    value: assets.from_asset(mock_policy_id, mock_asset_name, 100),
    datum: NoDatum,
    reference_script: None,
  }
  
  let tx = Transaction {
    ..mock_tx(),
    outputs: [script_output],
  }

  syndicate.syndicate_escrow.spend(Some(datum), redeemer, mock_utxo_ref(), tx)
}

test finalize_success() {
  let datum = mock_datum()
  let redeemer = Finalize
  
  // Mock output to seller with sufficient funds
  let seller_output = Output {
    address: address.from_verification_key(datum.seller),
    value: assets.from_asset(mock_policy_id, mock_asset_name, 1000),
    datum: NoDatum,
    reference_script: None,
  }
  
  let tx = Transaction {
    ..mock_tx(),
    outputs: [seller_output],
  }

  syndicate.syndicate_escrow.spend(Some(datum), redeemer, mock_utxo_ref(), tx)
}

test refund_success() {
  let datum = mock_datum()
  let redeemer = Refund
  
  // Mock time after deadline
  let validity_range = interval.after(101)
  
  let tx = Transaction {
    ..mock_tx(),
    validity_range: validity_range,
  }

  syndicate.syndicate_escrow.spend(Some(datum), redeemer, mock_utxo_ref(), tx)
}
