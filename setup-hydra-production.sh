#!/bin/bash
# =============================================================================
# PropFi Hydra Setup Script
# Generates production keys and configures Hydra node for property trading
# =============================================================================

set -e

echo "🌊 PropFi Hydra Production Setup"
echo "================================="

# Configuration
NETWORK="preprod"  # Change to "mainnet" for production
HYDRA_DIR="$HOME/hydra-propfi"
KEYS_DIR="$HYDRA_DIR/keys"
CONFIG_DIR="$HYDRA_DIR/config"
PERSISTENCE_DIR="$HYDRA_DIR/persistence"

# Create directories
echo "📁 Creating directories..."
mkdir -p "$KEYS_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$PERSISTENCE_DIR"

# =============================================================================
# 1. Generate Cardano Keys (for funding Hydra)
# =============================================================================
echo ""
echo "🔑 Generating Cardano keys..."

# Payment key for funding
if [ ! -f "$KEYS_DIR/funds.sk" ]; then
    cardano-cli address key-gen \
        --signing-key-file "$KEYS_DIR/funds.sk" \
        --verification-key-file "$KEYS_DIR/funds.vk"
    echo "  ✅ Created funding key pair"
else
    echo "  ⏭️  Funding keys already exist"
fi

# Generate address
if [ "$NETWORK" = "mainnet" ]; then
    NETWORK_MAGIC=""
else
    NETWORK_MAGIC="--testnet-magic 1"
fi

cardano-cli address build \
    --payment-verification-key-file "$KEYS_DIR/funds.vk" \
    $NETWORK_MAGIC \
    --out-file "$KEYS_DIR/funds.addr"

FUNDS_ADDR=$(cat "$KEYS_DIR/funds.addr")
echo "  📍 Funding address: $FUNDS_ADDR"

# =============================================================================
# 2. Generate Hydra Keys
# =============================================================================
echo ""
echo "🔐 Generating Hydra signing keys..."

if [ ! -f "$KEYS_DIR/hydra.sk" ]; then
    hydra-node gen-hydra-key --output-file "$KEYS_DIR/hydra"
    echo "  ✅ Created Hydra signing key"
else
    echo "  ⏭️  Hydra keys already exist"
fi

# =============================================================================
# 3. Create Hydra Node Configuration
# =============================================================================
echo ""
echo "⚙️  Creating Hydra node configuration..."

cat > "$CONFIG_DIR/hydra-node.json" << EOF
{
  "networkId": {
    "testnet": {
      "magic": 1
    }
  },
  "nodeSocket": "/tmp/cardano-node/node.socket",
  "hydraSigningKey": "$KEYS_DIR/hydra.sk",
  "hydraVerificationKeys": [],
  "cardanoSigningKey": "$KEYS_DIR/funds.sk",
  "cardanoVerificationKeys": [],
  "contestationPeriod": 120,
  "apiHost": "0.0.0.0",
  "apiPort": 4001,
  "host": "0.0.0.0",
  "port": 5001,
  "monitoringPort": 6001,
  "persistenceDir": "$PERSISTENCE_DIR",
  "ledgerProtocolParameters": "$CONFIG_DIR/protocol-parameters.json"
}
EOF

echo "  ✅ Created hydra-node.json"

# =============================================================================
# 4. Fetch Protocol Parameters
# =============================================================================
echo ""
echo "📜 Fetching protocol parameters..."

if command -v cardano-cli &> /dev/null; then
    cardano-cli query protocol-parameters \
        $NETWORK_MAGIC \
        --out-file "$CONFIG_DIR/protocol-parameters.json" 2>/dev/null || \
    echo "  ⚠️  Could not fetch from node, using default parameters"
fi

# Create default protocol parameters if not fetched
if [ ! -f "$CONFIG_DIR/protocol-parameters.json" ]; then
    cat > "$CONFIG_DIR/protocol-parameters.json" << 'EOF'
{
  "collateralPercentage": 150,
  "costModels": {},
  "executionUnitPrices": {
    "pricesMemory": 0.0577,
    "pricesSteps": 0.0000721
  },
  "maxBlockBodySize": 90112,
  "maxBlockExecutionUnits": {
    "exUnitsMem": 62000000,
    "exUnitsSteps": 20000000000
  },
  "maxBlockHeaderSize": 1100,
  "maxCollateralInputs": 3,
  "maxTxExecutionUnits": {
    "exUnitsMem": 14000000,
    "exUnitsSteps": 10000000000
  },
  "maxTxSize": 16384,
  "maxValueSize": 5000,
  "minPoolCost": 340000000,
  "monetaryExpansion": 0.003,
  "poolPledgeInfluence": 0.3,
  "poolRetireMaxEpoch": 18,
  "protocolVersion": {
    "major": 8,
    "minor": 0
  },
  "stakeAddressDeposit": 2000000,
  "stakePoolDeposit": 500000000,
  "stakePoolTargetNum": 500,
  "treasuryCut": 0.2,
  "txFeeFixed": 155381,
  "txFeePerByte": 44,
  "utxoCostPerByte": 4310
}
EOF
    echo "  ✅ Created default protocol parameters"
fi

# =============================================================================
# 5. Create Start Script
# =============================================================================
echo ""
echo "📝 Creating start script..."

cat > "$HYDRA_DIR/start-hydra-node.sh" << EOF
#!/bin/bash
# Start PropFi Hydra Node

HYDRA_DIR="$HYDRA_DIR"

echo "🌊 Starting PropFi Hydra Node..."
echo "   API: ws://0.0.0.0:4001"
echo "   P2P: 0.0.0.0:5001"

hydra-node \\
    --node-id propfi-1 \\
    --persistence-dir "\$HYDRA_DIR/persistence" \\
    --hydra-signing-key "\$HYDRA_DIR/keys/hydra.sk" \\
    --cardano-signing-key "\$HYDRA_DIR/keys/funds.sk" \\
    --ledger-protocol-parameters "\$HYDRA_DIR/config/protocol-parameters.json" \\
    --testnet-magic 1 \\
    --node-socket /tmp/cardano-node/node.socket \\
    --api-host 0.0.0.0 \\
    --api-port 4001 \\
    --host 0.0.0.0 \\
    --port 5001 \\
    --monitoring-port 6001 \\
    --contestation-period 120
EOF

chmod +x "$HYDRA_DIR/start-hydra-node.sh"
echo "  ✅ Created start-hydra-node.sh"

# =============================================================================
# 6. Summary
# =============================================================================
echo ""
echo "============================================="
echo "✅ PropFi Hydra Setup Complete!"
echo "============================================="
echo ""
echo "📁 Files created in: $HYDRA_DIR"
echo ""
echo "🔑 Keys:"
echo "   - Funding key: $KEYS_DIR/funds.sk"
echo "   - Hydra key: $KEYS_DIR/hydra.sk"
echo ""
echo "📍 Fund this address to use Hydra:"
echo "   $FUNDS_ADDR"
echo ""
if [ "$NETWORK" = "preprod" ]; then
echo "💧 Get test ADA from faucet:"
echo "   https://docs.cardano.org/cardano-testnet/tools/faucet/"
fi
echo ""
echo "🚀 To start the Hydra node:"
echo "   cd $HYDRA_DIR && ./start-hydra-node.sh"
echo ""
echo "🔗 Connect from Flutter app:"
echo "   ws://localhost:4001"
echo ""
