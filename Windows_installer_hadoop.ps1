# =============================================================================
#  Hadoop 3.2.3 — Automated Installer for Windows 10/11 (via WSL2)
#  Run this script in PowerShell as Administrator.
#  Usage:  Right-click PowerShell → "Run as Administrator"
#          .\install_hadoop.ps1
# =============================================================================

$ErrorActionPreference = "Stop"

function Info    { param($msg) Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Success { param($msg) Write-Host "[OK]    $msg" -ForegroundColor Green }
function Warn    { param($msg) Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Err     { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }

# =============================================================================
# STEP 0 — Preflight checks
# =============================================================================
Info "Starting Hadoop 3.2.3 automated installation on Windows..."

# Must be run as Administrator
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Err "Please run this script as Administrator (right-click PowerShell → Run as Administrator)."
}

# Check Windows version (WSL2 requires Windows 10 build 19041+ or Windows 11)
$build = [System.Environment]::OSVersion.Version.Build
if ($build -lt 19041) {
    Err "WSL2 requires Windows 10 build 19041 or later. Your build: $build. Please update Windows."
}
Info "Windows build $build — OK."

# =============================================================================
# STEP 1 — Enable WSL2 and Virtual Machine Platform
# =============================================================================
Info "Enabling Windows Subsystem for Linux (WSL)..."
$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
if ($wslFeature.State -ne "Enabled") {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    Success "WSL feature enabled."
} else {
    Warn "WSL already enabled — skipping."
}

Info "Enabling Virtual Machine Platform..."
$vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
if ($vmFeature.State -ne "Enabled") {
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    Success "Virtual Machine Platform enabled."
} else {
    Warn "Virtual Machine Platform already enabled — skipping."
}

# =============================================================================
# STEP 2 — Install WSL2 kernel update & set default version
# =============================================================================
Info "Setting WSL default version to 2..."
wsl --set-default-version 2 2>$null
if ($LASTEXITCODE -ne 0) {
    Warn "Could not set WSL default to 2. Attempting to install/update WSL kernel..."
    # Download and install WSL2 kernel update
    $kernelUrl  = "https://wslstorestorage.blob.core.windows.net/wslblob/wsl_update_x64.msi"
    $kernelPath = "$env:TEMP\wsl_update_x64.msi"
    Info "Downloading WSL2 kernel update..."
    Invoke-WebRequest -Uri $kernelUrl -OutFile $kernelPath -UseBasicParsing
    Start-Process msiexec.exe -ArgumentList "/i `"$kernelPath`" /quiet /norestart" -Wait
    Success "WSL2 kernel installed."
    wsl --set-default-version 2
}
Success "WSL2 set as default."

# =============================================================================
# STEP 3 — Install Ubuntu 22.04 via WSL
# =============================================================================
Info "Checking for Ubuntu 22.04 WSL distribution..."
$distros = wsl --list --quiet 2>$null
$ubuntuInstalled = $distros -match "Ubuntu-22.04"

if (-not $ubuntuInstalled) {
    Info "Installing Ubuntu 22.04 LTS from Microsoft Store (this may take several minutes)..."
    wsl --install -d Ubuntu-22.04
    Success "Ubuntu 22.04 installed."
    Write-Host ""
    Write-Host "  ============================================================" -ForegroundColor Yellow
    Write-Host "  Ubuntu 22.04 has been installed." -ForegroundColor Yellow
    Write-Host "  A RESTART may be required before continuing." -ForegroundColor Yellow
    Write-Host "  After restarting:" -ForegroundColor Yellow
    Write-Host "   1. Ubuntu will open automatically to set up your UNIX user." -ForegroundColor Yellow
    Write-Host "   2. Set your username and password when prompted." -ForegroundColor Yellow
    Write-Host "   3. Then re-run this script to continue Hadoop installation." -ForegroundColor Yellow
    Write-Host "  ============================================================" -ForegroundColor Yellow
    Write-Host ""
    $restart = Read-Host "Restart now? (y/n)"
    if ($restart -eq "y") { Restart-Computer }
    exit 0
} else {
    Warn "Ubuntu 22.04 already installed — skipping WSL distro install."
}

# =============================================================================
# STEP 4 — Copy the Linux installer script into WSL and run it
# =============================================================================
Info "Preparing Hadoop installer for Ubuntu (WSL)..."

# Determine path to the bash installer (same directory as this script)
$scriptDir       = Split-Path -Parent $MyInvocation.MyCommand.Path
$bashInstaller   = Join-Path $scriptDir "install_hadoop.sh"

if (-not (Test-Path $bashInstaller)) {
    Err "install_hadoop.sh not found in $scriptDir. Place both files in the same directory."
}

# Convert Windows path to WSL path
$wslPath = wsl wslpath -u "$($bashInstaller -replace '\\', '/')"

Info "Copying install_hadoop.sh into WSL home directory..."
wsl -d Ubuntu-22.04 -- bash -c "cp '$wslPath' ~/install_hadoop.sh && chmod +x ~/install_hadoop.sh"
Success "Script copied."

Info "Running Hadoop installer inside Ubuntu (WSL)..."
Info "You will be prompted to set a password for the new 'hadoop' user."
Info "Suggested password: hadoop"
Write-Host ""

wsl -d Ubuntu-22.04 -- bash -c "~/install_hadoop.sh"

if ($LASTEXITCODE -ne 0) {
    Warn "Installer exited with code $LASTEXITCODE — check output above for errors."
} else {
    Success "Hadoop installer completed inside WSL."
}

# =============================================================================
# STEP 5 — Create handy Windows shortcuts / helper scripts
# =============================================================================
Info "Creating helper batch files on Desktop..."

$desktop = [System.Environment]::GetFolderPath("Desktop")

# start-hadoop.bat
@"
@echo off
echo Starting Hadoop inside WSL (Ubuntu 22.04)...
wsl -d Ubuntu-22.04 -u hadoop -- bash -c "export HADOOP_HOME=/home/hadoop/hadoop-3.2.3 && export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64 && export PATH=\$PATH:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin && start-dfs.sh && start-yarn.sh && echo Hadoop started. && jps"
pause
"@ | Set-Content "$desktop\start-hadoop.bat"

# stop-hadoop.bat
@"
@echo off
echo Stopping Hadoop inside WSL (Ubuntu 22.04)...
wsl -d Ubuntu-22.04 -u hadoop -- bash -c "export HADOOP_HOME=/home/hadoop/hadoop-3.2.3 && export PATH=\$PATH:\$HADOOP_HOME/sbin && stop-yarn.sh && stop-dfs.sh && echo Hadoop stopped."
pause
"@ | Set-Content "$desktop\stop-hadoop.bat"

# hadoop-shell.bat
@"
@echo off
echo Opening Hadoop shell (Ubuntu WSL as hadoop user)...
wsl -d Ubuntu-22.04 -u hadoop
"@ | Set-Content "$desktop\hadoop-shell.bat"

Success "Helper scripts created on Desktop: start-hadoop.bat, stop-hadoop.bat, hadoop-shell.bat"

# =============================================================================
# DONE
# =============================================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Hadoop 3.2.3 Installation Complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  HDFS NameNode UI  ->  http://localhost:9870" -ForegroundColor Cyan
Write-Host "  YARN Resource Mgr ->  http://localhost:8088" -ForegroundColor Cyan
Write-Host "  Secondary NameNode->  http://localhost:9868" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Open these URLs in your Windows browser after Hadoop starts." -ForegroundColor White
Write-Host ""
Write-Host "  Desktop shortcuts created:" -ForegroundColor White
Write-Host "    start-hadoop.bat  — start all daemons" -ForegroundColor Yellow
Write-Host "    stop-hadoop.bat   — stop all daemons" -ForegroundColor Yellow
Write-Host "    hadoop-shell.bat  — open WSL shell as hadoop user" -ForegroundColor Yellow
Write-Host ""
Write-Host "  To verify daemons manually:" -ForegroundColor White
Write-Host "    wsl -d Ubuntu-22.04 -u hadoop -- jps" -ForegroundColor Yellow
Write-Host ""
