# Crestadel Hydra Integration Guide

## Overview

This guide helps you set up Hydra Layer 2 for instant, low-cost property fraction trading in Crestadel. You'll run the Hydra node in WSL (Linux) while keeping your Flutter development on Windows.

## Architecture

```
┌─────────────────────────────────────────────────┐
│             Windows (Your Machine)              │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  Flutter App (runs on Windows)          │   │
│  │  - Connects to: ws://localhost:4001     │   │
│  │  - Uses HydraService for L2 txs         │   │
│  └──────────────────┬──────────────────────┘   │
│                     │ WebSocket                │
│                     ↓                           │
│  ┌─────────────────────────────────────────┐   │
│  │   Port Forward (localhost:4001)         │   │
│  └──────────────────┬──────────────────────┘   │
│                     │                           │
│  ┌──────────────────────────────────────────┐  │
│  │           WSL 2 (Ubuntu)                 │  │
│  │  ┌────────────────────────────────────┐  │  │
│  │  │  Hydra Node                        │  │  │
│  │  │  - Listens on: 0.0.0.0:4001        │  │  │
│  │  │  - Offline mode (no cardano-node)  │  │  │
│  │  └────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

## Quick Start

### 1. Setup Hydra Node in WSL

Open WSL terminal and run:

```bash
cd /mnt/t/CODES/cardano
bash hydra-node-setup.sh
```

This script will:
- Download Hydra node binary
- Generate cryptographic keys
- Create configuration files
- Set up a convenient run script

### 2. Setup Port Forwarding (Windows)

Open PowerShell **as Administrator** and run:

```powershell
cd T:\CODES\cardano
.\setup-hydra-port-forwarding.ps1
```

This will:
- Find your WSL IP address
- Configure Windows Firewall
- Set up port forwarding from Windows localhost:4001 to WSL

### 3. Start Hydra Node

In WSL:

```bash
cd ~/hydra-node
./run-hydra.sh
```

You should see:
```
======================================
Starting Hydra Node
======================================
Network: preview
API Port: 4001 (WebSocket)
Monitoring: 6001

Connect your Flutter app to: ws://localhost:4001
```

### 4. Run Your Flutter App

In Windows terminal (or VS Code terminal):

```powershell
cd T:\CODES\cardano\frontend
flutter run -d chrome
```

## Using Hydra in Your App

### Connect to Hydra

```dart
import 'package:provider/provider.dart';
import 'services/hydra_service.dart';
import 'features/hydra/hydra_status_widget.dart';

// In your widget
final hydraService = Provider.of<HydraService>(context);

// Connect
await hydraService.connect('ws://localhost:4001');

// Initialize a Head
await hydraService.initHead();
```

### Use Hydra Status Widget

Add to your UI to show connection status and controls:

```dart
// Compact version (for app bar)
HydraStatusWidget(compact: true)

// Full version (for settings page)
HydraStatusWidget(compact: false)
```

### Submit Transactions to L2

```dart
final certService = Provider.of<CertificateService>(context);

// Check if Hydra is available
if (certService.isHydraAvailable) {
  // Submit to Hydra for instant confirmation
  bool success = await certService.submitToHydra(txCborHex);
  
  if (success) {
    print('Transaction confirmed instantly on L2!');
  }
} else {
  // Fall back to regular L1 transaction
  print('Hydra not available, using Layer 1');
}
```

## Hydra Lifecycle

1. **Idle** - Hydra node running, no Head open
2. **Initializing** - Head initialization in progress
3. **Open** - Head is open, can process transactions instantly
4. **Closed** - Head closed, preparing to settle on L1
5. **Finalized** - All transactions settled back to L1

## Commands

### WSL (Hydra Node)

```bash
# Start Hydra node
cd ~/hydra-node && ./run-hydra.sh

# Check if Hydra is running
ps aux | grep hydra-node

# Stop Hydra
pkill hydra-node

# View logs
cd ~/hydra-node
# Logs will be in the terminal where you ran ./run-hydra.sh
```

### Windows (Port Forwarding)

```powershell
# Check current port forwarding
netsh interface portproxy show all

# Remove port forwarding
netsh interface portproxy delete v4tov4 listenport=4001 listenaddress=0.0.0.0

# Re-run setup
.\setup-hydra-port-forwarding.ps1
```

### Finding WSL IP (if needed)

In WSL:
```bash
ip addr show eth0 | grep "inet "
```

Or from Windows PowerShell:
```powershell
wsl hostname -I
```

## Troubleshooting

### "Connection refused" in Flutter app

1. Check if Hydra node is running in WSL:
   ```bash
   ps aux | grep hydra-node
   ```

2. Check if port forwarding is set up:
   ```powershell
   netsh interface portproxy show all
   ```
   Should show: `0.0.0.0:4001` → `<WSL-IP>:4001`

3. Test WebSocket from Windows:
   - Open browser to: `http://localhost:4001`
   - Should get WebSocket response or error (not "connection refused")

### WSL IP changed

WSL IP can change when you restart Windows. Re-run:
```powershell
.\setup-hydra-port-forwarding.ps1
```

### Firewall blocking connection

Run PowerShell as Admin:
```powershell
New-NetFirewallRule -DisplayName "Hydra Node" -Direction Inbound -LocalPort 4001 -Protocol TCP -Action Allow
```

### Hydra node crashes

Check the terminal output where you ran `./run-hydra.sh`. Common issues:
- Port already in use: `lsof -i :4001` or change port in `run-hydra.sh`
- Permission denied: `chmod +x ~/hydra-node/hydra-node`

## Advanced Configuration

### Changing Hydra Port

Edit `~/hydra-node/run-hydra.sh`:
```bash
API_PORT=4002  # Change from 4001
```

Then update port forwarding and Flutter app connection URL.

### Using Multiple Hydra Nodes

You can run multiple Hydra nodes on different ports for testing:

```bash
# Node 1 on port 4001
./hydra-node offline --api-port 4001 ...

# Node 2 on port 4002
./hydra-node offline --api-port 4002 ...
```

### Connecting to Real Cardano Network

To connect Hydra to a real Cardano node (not offline mode):

1. Install and sync `cardano-node` in WSL
2. Edit `run-hydra.sh` to use `--cardano-node` instead of `offline`
3. Provide node socket path: `--node-socket /path/to/node.socket`

## Benefits of Hydra L2

- ⚡ **Instant Transactions**: Confirmations in milliseconds
- 💰 **Near-Zero Fees**: No transaction fees within the Head
- 🔒 **Secure**: Cryptographically secured, fully decentralized
- 🔄 **Settles to L1**: Final settlement on Cardano mainnet

## Use Cases in Crestadel

1. **Fast Trading**: Trade property fractions instantly between users
2. **Micro-transactions**: Small purchases without high fees
3. **Auctions**: Real-time bidding without waiting for confirmations
4. **Gaming**: In-app rewards and achievements
5. **Testing**: Rapid development iteration without testnet delays

## Links

- [Hydra Documentation](https://hydra.family/head-protocol/)
- [Hydra GitHub](https://github.com/input-output-hk/hydra)
- [Cardano Docs](https://docs.cardano.org/)

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review Hydra message history in the UI
3. Check WSL and PowerShell terminal outputs
4. Verify network connectivity between Windows and WSL

---

**Made with ⚡ by Crestadel Team**
