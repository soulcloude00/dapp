# Crestadel Hydra Quick Start
# This script starts everything you need for Hydra development

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "   Crestadel Hydra Quick Start" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Check if WSL is available
Write-Host "Checking WSL..." -ForegroundColor Yellow
$wslCheck = wsl --list --quiet 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: WSL not found or not running" -ForegroundColor Red
    Write-Host "Please install WSL first: wsl --install" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "WSL is available" -ForegroundColor Green
Write-Host ""

# Check if Hydra setup was done
Write-Host "Checking Hydra setup..." -ForegroundColor Yellow
$hydraExists = wsl bash -c "test -f ~/hydra-node/hydra-node && echo yes || echo no"
if ($hydraExists.Trim() -ne "yes") {
    Write-Host "Hydra node not set up yet." -ForegroundColor Yellow
    Write-Host "Running setup script..." -ForegroundColor Yellow
    Write-Host ""
    
    wsl bash /mnt/t/CODES/cardano/hydra-node-setup.sh
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "ERROR: Hydra setup failed" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}
else {
    Write-Host "Hydra node is set up" -ForegroundColor Green
}
Write-Host ""

# Setup port forwarding
Write-Host "Setting up port forwarding..." -ForegroundColor Yellow
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Port forwarding requires Administrator privileges." -ForegroundColor Yellow
    Write-Host "Restarting with elevation..." -ForegroundColor Yellow
    Write-Host ""
    
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
    exit 0
}

# We have admin, set up port forwarding
$wslIpRaw = wsl hostname -I
$wslIp = $wslIpRaw.Trim().Split()[0]
Write-Host "WSL IP: $wslIp" -ForegroundColor Cyan

# Remove old forwarding
netsh interface portproxy delete v4tov4 listenport=4001 listenaddress=0.0.0.0 2>$null | Out-Null

# Add new forwarding
netsh interface portproxy add v4tov4 listenport=4001 listenaddress=0.0.0.0 connectport=4001 connectaddress=$wslIp | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "Port forwarding configured (localhost:4001 -> ${wslIp}:4001)" -ForegroundColor Green
}
else {
    Write-Host "Warning: Port forwarding may have failed" -ForegroundColor Yellow
}

# Configure firewall
$ruleName = "Hydra Node WebSocket"
$existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if (-not $existingRule) {
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort 4001 -Protocol TCP -Action Allow | Out-Null
    Write-Host "Firewall rule created" -ForegroundColor Green
}
else {
    Write-Host "Firewall rule already exists" -ForegroundColor Green
}
Write-Host ""

Write-Host "======================================" -ForegroundColor Green
Write-Host "   Starting Hydra Node" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

Write-Host "Hydra node is starting in WSL..." -ForegroundColor Cyan
Write-Host "This window will show Hydra logs." -ForegroundColor Cyan
Write-Host ""
Write-Host "To connect from Flutter:" -ForegroundColor Yellow
Write-Host "  ws://localhost:4001" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the Hydra node" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Green
Write-Host ""

# Start Hydra in WSL (this will block and show logs)
wsl bash -c "cd ~/hydra-node; ./run-hydra.sh"

Write-Host ""
Write-Host "Hydra node stopped." -ForegroundColor Yellow
Read-Host "Press Enter to exit"
