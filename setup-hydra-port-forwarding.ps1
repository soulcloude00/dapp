# Hydra Port Forwarding Setup for Windows
# Run this in PowerShell as Administrator to forward WSL Hydra node to Windows

Write-Host "====================================== " -ForegroundColor Green
Write-Host "Crestadel Hydra Port Forwarding Setup" -ForegroundColor Green
Write-Host "======================================`n" -ForegroundColor Green

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "Step 1: Finding WSL IP Address..." -ForegroundColor Yellow

# Get WSL IP address
$wslIp = wsl hostname -I
$wslIp = $wslIp.Trim().Split()[0]

if ([string]::IsNullOrWhiteSpace($wslIp)) {
    Write-Host "ERROR: Could not find WSL IP. Is WSL running?" -ForegroundColor Red
    pause
    exit 1
}

Write-Host "WSL IP found: $wslIp" -ForegroundColor Green

Write-Host "`nStep 2: Configuring Windows Firewall..." -ForegroundColor Yellow

# Allow incoming connections on port 4001
$ruleName = "Hydra Node WebSocket"
$existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue

if ($existingRule) {
    Write-Host "Firewall rule already exists, updating..." -ForegroundColor Yellow
    Remove-NetFirewallRule -DisplayName $ruleName
}

New-NetFirewallRule -DisplayName $ruleName `
    -Direction Inbound `
    -LocalPort 4001 `
    -Protocol TCP `
    -Action Allow | Out-Null

Write-Host "Firewall rule created" -ForegroundColor Green

Write-Host "`nStep 3: Setting up Port Forwarding..." -ForegroundColor Yellow

# Remove existing port proxy if exists
netsh interface portproxy delete v4tov4 listenport=4001 listenaddress=0.0.0.0 2>$null

# Add new port proxy
netsh interface portproxy add v4tov4 `
    listenport=4001 `
    listenaddress=0.0.0.0 `
    connectport=4001 `
    connectaddress=$wslIp

if ($LASTEXITCODE -eq 0) {
    Write-Host "Port forwarding configured successfully" -ForegroundColor Green
} else {
    Write-Host "ERROR: Failed to configure port forwarding" -ForegroundColor Red
    pause
    exit 1
}

Write-Host "`n====================================== " -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "======================================`n" -ForegroundColor Green

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  WSL IP: $wslIp"
Write-Host "  Forward: localhost:4001 -> $wslIp:4001"
Write-Host ""
Write-Host "Your Flutter app can now connect to: ws://localhost:4001" -ForegroundColor Green
Write-Host ""
Write-Host "To start the Hydra node in WSL, run:" -ForegroundColor Yellow
Write-Host "  wsl cd ~/hydra-node && ./run-hydra.sh" -ForegroundColor White
Write-Host ""
Write-Host "To remove port forwarding later, run:" -ForegroundColor Yellow
Write-Host "  netsh interface portproxy delete v4tov4 listenport=4001 listenaddress=0.0.0.0" -ForegroundColor White
Write-Host ""

# Show current port forwarding rules
Write-Host "Current port forwarding rules:" -ForegroundColor Cyan
netsh interface portproxy show all

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
