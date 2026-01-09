<#
.NOTES
===========================================================================
Name:           Manage-CloudRadial-DesktopTray
Created by:     Chris Dewey
Updated:        2026.01.08
Version:        1.1
Status:         Active/Development
Changes:
    v1.0 2026.01.07 - Initial version
    v1.1 2026.01.08 - Improved download/install reliability, added uninstall support
===========================================================================
.DESCRIPTION
    Installs or removes the CloudRadial Desktop Tray Agent.

    Install:
      - Downloads installer to C:\Source\ScriptFiles
      - Runs installer silently

    Remove:
      - Runs the known uninstaller silently if present
#>

# =========================
# USER CONTROLS (EDIT HERE)
# =========================
$Action = 'Install'      # Install | Remove

$CloudRadialDesktopTray = "[URL to CloudRadial Desktop Tray Agent installer]"

# Uninstall details (provided)
$UninstallerExe = "C:\Program Files (x86)\[Your Client Portal Directory]\unins000.exe"
$UninstallArgs  = "/norestart /verysilent"

# =========================
# DO NOT EDIT BELOW
# =========================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Paths
$SourcePath      = "C:\Source"
$ScriptFilesPath = Join-Path -Path $SourcePath -ChildPath "ScriptFiles"
$LogPath         = Join-Path -Path $SourcePath -ChildPath "Logs"
$LogFile         = Join-Path -Path $LogPath -ChildPath "CloudRadialDesktopTray.log"

$InstallerPath   = Join-Path -Path $ScriptFilesPath -ChildPath "CloudRadialDesktopTrayAgent.exe"

# Create directories
$null = New-Item -ItemType Directory -Path $SourcePath      -Force -ErrorAction SilentlyContinue
$null = New-Item -ItemType Directory -Path $ScriptFilesPath -Force -ErrorAction SilentlyContinue
$null = New-Item -ItemType Directory -Path $LogPath         -Force -ErrorAction SilentlyContinue

function Write-Log {
    param([Parameter(Mandatory)][string]$Message)

    $line = "{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    $line | Tee-Object -FilePath $LogFile -Append | Out-Host
}

function Set-TlsForDownloads {
    # Prefer TLS 1.2+; TLS 1.3 may not exist on older .NET
    try {
        [Net.ServicePointManager]::SecurityProtocol = `
            [Net.SecurityProtocolType]::Tls12 -bor `
            [Net.SecurityProtocolType]::Tls13
    } catch {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
}

function Get-File {
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$OutFile
    )

    Set-TlsForDownloads

    # Clean up any previous partial file
    if (Test-Path $OutFile) {
        try { Remove-Item -Path $OutFile -Force -ErrorAction Stop } catch {}
    }

    Write-Log "Downloading: $Url"
    Write-Log "To:         $OutFile"

    # Prefer Invoke-WebRequest; fallback to WebClient if needed
    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Log "Invoke-WebRequest failed, falling back to WebClient. Error: $($_.Exception.Message)"
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile($Url, $OutFile)
    }

    if (-not (Test-Path $OutFile)) {
        throw "Download failed; file not found at $OutFile"
    }

    $size = (Get-Item $OutFile).Length
    if ($size -lt 1024) {
        throw "Download looks invalid (file size $size bytes)."
    }

    Write-Log "Download complete ($size bytes)."
}

function Invoke-Installer {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string]$Arguments,
        [Parameter(Mandatory)][string]$DisplayName
    )

    if (-not (Test-Path $FilePath)) {
        throw "$DisplayName not found at: $FilePath"
    }

    Write-Log "Starting ${DisplayName}: `"${FilePath}`" ${Arguments}"
    $p = Start-Process -FilePath $FilePath -ArgumentList $Arguments -Wait -PassThru -WindowStyle Hidden
    Write-Log "$DisplayName exit code: $($p.ExitCode)"

    # Common success codes:
    # 0    = Success
    # 3010 = Success, reboot required
    if ($p.ExitCode -eq 0) { return 0 }
    if ($p.ExitCode -eq 3010) { return 3010 }

    throw "$DisplayName failed with exit code $($p.ExitCode)."
}

# =========================
# MAIN
# =========================

try {
    Write-Log "======== Script start ========"
    Write-Log "Action: $Action"
    Write-Log "Log:    $LogFile"

    switch ($Action) {
        'Install' {
            Get-File -Url $CloudRadialDesktopTray -OutFile $InstallerPath

            # Install silently
            $InstallArgs = "/verysilent logging=true"
            $code = Invoke-Installer -FilePath $InstallerPath -Arguments $InstallArgs -DisplayName "Installer"

            if ($code -eq 3010) {
                Write-Log "Install completed successfully (reboot required)."
            } else {
                Write-Log "Install completed successfully."
            }
        }

        'Remove' {
            if (-not (Test-Path $UninstallerExe)) {
                Write-Log "Uninstaller not found at: $UninstallerExe"
                Write-Log "Nothing to uninstall (or path differs on this device)."
                break
            }

            $code = Invoke-Installer -FilePath $UninstallerExe -Arguments $UninstallArgs -DisplayName "Uninstaller"

            if ($code -eq 3010) {
                Write-Log "Uninstall completed successfully (reboot required)."
            } else {
                Write-Log "Uninstall completed successfully."
            }
        }

        default {
            throw "Invalid Action '$Action'. Use Install or Remove."
        }
    }

    Write-Log "======== Script end (success) ========"
}
catch {
    Write-Log "======== Script end (error) ========"
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
}
