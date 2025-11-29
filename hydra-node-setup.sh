#!/bin/bash
# Hydra Node Setup Script for WSL
# This script downloads and runs a Hydra node that connects to your Windows Flutter app

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}======================================"
echo "Crestadel Hydra Node Setup (WSL)"
echo -e "======================================${NC}\n"

# Configuration
HYDRA_VERSION="0.18.1"
HYDRA_DIR="$HOME/hydra-node"
CARDANO_NODE_SOCKET="${CARDANO_NODE_SOCKET:-/tmp/cardano-node.socket}"
NETWORK="preview"

# Check if running in WSL
if ! grep -qi microsoft /proc/version; then
    echo -e "${RED}Warning: This script is designed for WSL. You may encounter issues.${NC}"
fi

# Create hydra directory
mkdir -p "$HYDRA_DIR"
cd "$HYDRA_DIR"

echo -e "${YELLOW}Step 1: Downloading Hydra Node...${NC}"

# Download Hydra binary if not exists
if [ ! -f "hydra-node" ]; then
    HYDRA_URL="https://github.com/input-output-hk/hydra/releases/download/${HYDRA_VERSION}/hydra-x86_64-linux-${HYDRA_VERSION}.zip"
    
    if command -v wget &> /dev/null; then
        wget -O hydra.zip "$HYDRA_URL"
    elif command -v curl &> /dev/null; then
        curl -L -o hydra.zip "$HYDRA_URL"
    else
        echo -e "${RED}Error: Neither wget nor curl found. Please install one.${NC}"
        exit 1
    fi
    
    # Extract
    if command -v unzip &> /dev/null; then
        unzip -o hydra.zip
    else
        echo -e "${RED}Error: unzip not found. Install with: sudo apt install unzip${NC}"
        exit 1
    fi
    
    chmod +x hydra-node
    rm hydra.zip
    echo -e "${GREEN}✓ Hydra node downloaded${NC}"
else
    echo -e "${GREEN}✓ Hydra node already exists${NC}"
fi

echo -e "\n${YELLOW}Step 2: Generating Hydra Keys (if needed)...${NC}"

# Generate keys if not exist
if [ ! -f "alice.sk" ]; then
    ./hydra-node gen-hydra-key --output-file alice
    echo -e "${GREEN}✓ Generated Hydra signing key (alice)${NC}"
else
    echo -e "${GREEN}✓ Hydra keys already exist${NC}"
fi

# Generate Cardano keys if needed
if [ ! -f "alice-cardano.sk" ]; then
    if command -v cardano-cli &> /dev/null; then
        cardano-cli address key-gen \
            --verification-key-file alice-cardano.vk \
            --signing-key-file alice-cardano.sk
        echo -e "${GREEN}✓ Generated Cardano keys${NC}"
    else
        echo -e "${YELLOW}Warning: cardano-cli not found. You may need Cardano keys for some operations.${NC}"
    fi
fi

echo -e "\n${YELLOW}Step 3: Configuration${NC}"

# Get Windows host IP for WSL2
WINDOWS_HOST=$(ip route | grep default | awk '{print $3}')
echo -e "Windows host IP: ${GREEN}$WINDOWS_HOST${NC}"

# Create a simple run script
cat > run-hydra.sh << 'RUNSCRIPT'
#!/bin/bash
# Run Hydra Node for Crestadel

HYDRA_DIR="$HOME/hydra-node"
cd "$HYDRA_DIR"

# Configuration
NETWORK="preview"
API_PORT=4001
MONITORING_PORT=6001

echo "======================================"
echo "Starting Hydra Node"
echo "======================================"
echo "Network: $NETWORK"
echo "API Port: $API_PORT (WebSocket)"
echo "Monitoring: $MONITORING_PORT"
echo ""
echo "Connect your Flutter app to: ws://localhost:$API_PORT"
echo "Or from Windows: ws://<WSL-IP>:$API_PORT"
echo ""
echo "Press Ctrl+C to stop"
echo "======================================"

# Run Hydra in offline mode (no cardano-node connection needed for testing)
./hydra-node offline \
    --hydra-signing-key alice.sk \
    --api-port $API_PORT \
    --monitoring-port $MONITORING_PORT \
    --ledger-protocol-parameters preview-protocol-parameters.json

RUNSCRIPT

chmod +x run-hydra.sh

# Download protocol parameters for preview network
echo -e "\n${YELLOW}Step 4: Downloading protocol parameters...${NC}"

if [ ! -f "preview-protocol-parameters.json" ]; then
    cat > preview-protocol-parameters.json << 'EOF'
{
  "txFeePerByte": 44,
  "txFeeFixed": 155381,
  "maxBlockBodySize": 90112,
  "maxBlockHeaderSize": 1100,
  "maxTxSize": 16384,
  "stakeAddressDeposit": 2000000,
  "stakePoolDeposit": 500000000,
  "poolRetireMaxEpoch": 18,
  "stakePoolTargetNum": 500,
  "poolPledgeInfluence": 0.3,
  "monetaryExpansion": 0.003,
  "treasuryCut": 0.2,
  "minPoolCost": 340000000,
  "coinsPerUTxOByte": 4310,
  "costModels": {
    "PlutusV1": [205665, 812, 1, 1, 1000, 571, 0, 1, 1000, 24177, 4, 1, 1000, 32, 117366, 10475, 4, 23000, 100, 23000, 100, 23000, 100, 23000, 100, 23000, 100, 23000, 100, 100, 100, 23000, 100, 19537, 32, 175354, 32, 46417, 4, 221973, 511, 0, 1, 89141, 32, 497525, 14068, 4, 2, 196500, 453240, 220, 0, 1, 1, 1000, 28662, 4, 2, 245000, 216773, 62, 1, 1060367, 12586, 1, 208512, 421, 1, 187000, 1000, 52998, 1, 80436, 32, 43249, 32, 1000, 32, 80556, 1, 57667, 4, 1000, 10, 197145, 156, 1, 197145, 156, 1, 204924, 473, 1, 208896, 511, 1, 52467, 32, 64832, 32, 65493, 32, 22558, 32, 16563, 32, 76511, 32, 196500, 453240, 220, 0, 1, 1, 69522, 11687, 0, 1, 60091, 32, 196500, 453240, 220, 0, 1, 1, 196500, 453240, 220, 0, 1, 1, 1159724, 392670, 0, 2, 806990, 30482, 4, 1927926, 82523, 4, 265318, 0, 4, 0, 85931, 32, 205665, 812, 1, 1, 41182, 32, 212342, 32, 31220, 32, 32696, 32, 43357, 32, 32247, 32, 38314, 32, 20000000000, 20000000000, 9462713, 1021, 10, 20000000000, 0, 20000000000],
    "PlutusV2": [205665, 812, 1, 1, 1000, 571, 0, 1, 1000, 24177, 4, 1, 1000, 32, 117366, 10475, 4, 23000, 100, 23000, 100, 23000, 100, 23000, 100, 23000, 100, 23000, 100, 100, 100, 23000, 100, 19537, 32, 175354, 32, 46417, 4, 221973, 511, 0, 1, 89141, 32, 497525, 14068, 4, 2, 196500, 453240, 220, 0, 1, 1, 1000, 28662, 4, 2, 245000, 216773, 62, 1, 1060367, 12586, 1, 208512, 421, 1, 187000, 1000, 52998, 1, 80436, 32, 43249, 32, 1000, 32, 80556, 1, 57667, 4, 1000, 10, 197145, 156, 1, 197145, 156, 1, 204924, 473, 1, 208896, 511, 1, 52467, 32, 64832, 32, 65493, 32, 22558, 32, 16563, 32, 76511, 32, 196500, 453240, 220, 0, 1, 1, 69522, 11687, 0, 1, 60091, 32, 196500, 453240, 220, 0, 1, 1, 196500, 453240, 220, 0, 1, 1, 1159724, 392670, 0, 2, 806990, 30482, 4, 1927926, 82523, 4, 265318, 0, 4, 0, 85931, 32, 205665, 812, 1, 1, 41182, 32, 212342, 32, 31220, 32, 32696, 32, 43357, 32, 32247, 32, 38314, 32, 20000000000, 20000000000, 9462713, 1021, 10, 20000000000, 0, 20000000000, 38887044, 32947, 10]
  },
  "prices": {
    "prMem": 0.0577,
    "prSteps": 0.0000721
  },
  "maxTxExecutionUnits": {
    "exUnitsMem": 14000000,
    "exUnitsSteps": 10000000000
  },
  "maxBlockExecutionUnits": {
    "exUnitsMem": 62000000,
    "exUnitsSteps": 20000000000
  },
  "maxValueSize": 5000,
  "collateralPercentage": 150,
  "maxCollateralInputs": 3,
  "protocolVersion": {
    "major": 8,
    "minor": 0
  }
}
EOF
    echo -e "${GREEN}✓ Protocol parameters created${NC}"
fi

echo -e "\n${GREEN}======================================"
echo "Setup Complete!"
echo -e "======================================${NC}"
echo ""
echo "To start Hydra node, run:"
echo -e "  ${YELLOW}cd $HYDRA_DIR && ./run-hydra.sh${NC}"
echo ""
echo "The node will be available at:"
echo -e "  ${GREEN}ws://localhost:4001${NC} (from WSL)"
echo ""
echo "To access from Windows:"
echo "1. Find your WSL IP: ip addr show eth0 | grep inet"
echo "2. Connect to: ws://<WSL-IP>:4001"
echo ""
echo "Or use port forwarding in Windows PowerShell (as Admin):"
echo -e "  ${YELLOW}netsh interface portproxy add v4tov4 listenport=4001 listenaddress=0.0.0.0 connectport=4001 connectaddress=<WSL-IP>${NC}"
echo ""
echo -e "${YELLOW}Quick Start Guide:${NC}"
echo "1. Start the node: ./run-hydra.sh"
echo "2. In your Flutter app, connect to ws://localhost:4001"
echo "3. Use HydraService to init/commit/transact"
echo ""
