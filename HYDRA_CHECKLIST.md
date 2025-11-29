# Hydra Setup Checklist

Complete these steps to get Hydra Layer 2 running with your Flutter app on Windows.

## Prerequisites

- [ ] Windows 10/11 with WSL 2 installed
- [ ] Ubuntu or Debian distribution in WSL
- [ ] Flutter installed on Windows (not needed in WSL)
- [ ] Basic terminal/PowerShell knowledge

## Setup Steps

### 1. Initial Setup (One-time)

- [ ] Open WSL terminal
- [ ] Run: `cd /mnt/t/CODES/cardano`
- [ ] Run: `bash hydra-node-setup.sh`
- [ ] Wait for download and setup to complete
- [ ] Verify you see "Setup Complete!" message

### 2. Port Forwarding (One-time or after Windows restart)

- [ ] Open PowerShell as Administrator
- [ ] Navigate to: `cd T:\CODES\cardano`
- [ ] Run: `.\setup-hydra-port-forwarding.ps1`
- [ ] Verify you see "Setup Complete!" message
- [ ] Note the WSL IP address shown

### 3. Test Hydra Node

- [ ] In WSL, run: `cd ~/hydra-node && ./run-hydra.sh`
- [ ] You should see:
  ```
  ======================================
  Starting Hydra Node
  ======================================
  Network: preview
  API Port: 4001 (WebSocket)
  ```
- [ ] Keep this terminal open (Hydra is running)

### 4. Test Connection from Windows

- [ ] Open `T:\CODES\cardano\hydra-test.html` in Chrome/Edge
- [ ] URL should be: `ws://localhost:4001`
- [ ] Click "Connect"
- [ ] You should see "🟢 Connected" status
- [ ] Click "Init Head" to initialize
- [ ] Watch message log for "HeadIsInitializing" and "HeadIsOpen"

### 5. Test with Flutter App

- [ ] Open new PowerShell terminal (keep Hydra running in WSL)
- [ ] Run: `cd T:\CODES\cardano\frontend`
- [ ] Run: `flutter run -d chrome`
- [ ] Once app loads, look for Hydra status indicator
- [ ] Test connection to `ws://localhost:4001`

## Quick Start Command (After Initial Setup)

Instead of steps 3-4, just run this from Windows PowerShell:

```powershell
cd T:\CODES\cardano
.\start-hydra.ps1
```

This single command will:
- ✅ Check if Hydra is set up
- ✅ Configure port forwarding automatically  
- ✅ Start the Hydra node
- ✅ Show live logs

## Troubleshooting Checklist

### Connection Refused

- [ ] Is Hydra node running? Check WSL terminal
- [ ] Run in WSL: `ps aux | grep hydra-node`
- [ ] If not running, start it: `cd ~/hydra-node && ./run-hydra.sh`

### Port Forwarding Issues

- [ ] Get WSL IP: `wsl hostname -I`
- [ ] Check forwarding: `netsh interface portproxy show all`
- [ ] Should show: `0.0.0.0:4001` → `<WSL-IP>:4001`
- [ ] If missing, re-run `setup-hydra-port-forwarding.ps1` as Admin

### Firewall Blocking

- [ ] Open Windows Firewall settings
- [ ] Look for "Hydra Node WebSocket" rule
- [ ] If missing, run as Admin:
  ```powershell
  New-NetFirewallRule -DisplayName "Hydra Node" -Direction Inbound -LocalPort 4001 -Protocol TCP -Action Allow
  ```

### WSL IP Changed

- [ ] This happens after Windows restart
- [ ] Re-run: `.\setup-hydra-port-forwarding.ps1`
- [ ] Or use `.\start-hydra.ps1` which does this automatically

## Daily Development Workflow

1. **Morning Start**
   ```powershell
   cd T:\CODES\cardano
   .\start-hydra.ps1
   ```
   
2. **In another terminal, start Flutter**
   ```powershell
   cd T:\CODES\cardano\frontend
   flutter run -d chrome
   ```

3. **When done, just close terminals**
   - Ctrl+C in Hydra terminal to stop node
   - Flutter will stop when you close the app

## Verification

Everything working correctly when you see:

- ✅ Hydra node shows "API Port: 4001" message
- ✅ Test page shows "🟢 Connected"
- ✅ Flutter app shows Hydra status as "Open (Active)"
- ✅ Message log shows "HeadIsOpen" after Init

## Need Help?

1. Check `HYDRA_SETUP.md` for detailed documentation
2. Review logs in Hydra terminal for error messages
3. Try the test page (`hydra-test.html`) to isolate issues
4. Verify WSL and port forwarding are working

## Files Created

- `hydra-node-setup.sh` - WSL setup script
- `setup-hydra-port-forwarding.ps1` - Windows port forwarding
- `start-hydra.ps1` - Quick start script (recommended!)
- `hydra-test.html` - Connection test page
- `HYDRA_SETUP.md` - Full documentation

---

**Pro Tip**: Bookmark `start-hydra.ps1` - it's the easiest way to start!
