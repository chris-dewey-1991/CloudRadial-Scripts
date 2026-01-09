<#
.NOTES
===========================================================================
Name:           Manage-CloudRadial-DataAgent
Created by:     Chris Dewey
Updated:        2026.01.08
Version:        1.1
Status:         Active/Development
Changes:
    v1.1 2026.01.08 - Fixed action handling, safer installer filename, add service detection + verification
    v1.0 2026.01.07 - Initial version
===========================================================================
.DESCRIPTION
    Installs or removes the CloudRadial Data Agent.

    Install:
      - Downloads installer to C:\Source\ScriptFiles
      - Runs installer silently with /verysilent and optional /companyid

    Remove:
      - Runs the known uninstaller silently if present
#>

# =========================
# USER CONTROLS (EDIT HERE)
# =========================
$Action = 'install'      # install | remove

$CloudRadialDataAgent = "[URL to CloudRadial Desktop Tray Agent installer]"
$CompanyID            = "[CompanyID provided by CloudRadial]"

# Optional Security Key (leave blank if not enabled)
$SecurityKey          = "[Security Key provided by CloudRadial]"

# Uninstall details (provided)
$UninstallerExe = "C:\Program Files (x86)\CloudRadial Agent\unins000.exe"
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
$LogFile         = Join-Path -Path $LogPath -ChildPath "CloudRadialDataAgent.log"

# Service detection name (per CloudRadial recommendation)
$ServiceName = "CloudRadial"

# Static, safe installer filename
$InstallerPath = Join-Path -Path $ScriptFilesPath -ChildPath "CloudRadialDataAgent.exe"

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
    try {
        [Net.ServicePointManager]::SecurityProtocol =
            [Net.SecurityProtocolType]::Tls12 -bor
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

    if (Test-Path $OutFile) {
        try { Remove-Item -Path $OutFile -Force -ErrorAction Stop } catch {}
    }

    Write-Log "Downloading: $Url"
    Write-Log "To:         $OutFile"

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

    Write-Log "Starting ${DisplayName}: `"$FilePath`" $Arguments"
    $p = Start-Process -FilePath $FilePath -ArgumentList $Arguments -Wait -PassThru -WindowStyle Hidden
    Write-Log "$DisplayName exit code: $($p.ExitCode)"

    if ($p.ExitCode -eq 0) { return 0 }
    if ($p.ExitCode -eq 3010) { return 3010 }

    throw "$DisplayName failed with exit code $($p.ExitCode)."
}

function Test-CloudRadialInstalled {
    return [bool](Get-Service -Name $ServiceName -ErrorAction SilentlyContinue)
}

# =========================
# MAIN
# =========================

try {
    Write-Log "======== Script start ========"
    Write-Log "Action: $Action"
    Write-Log "Log:    $LogFile"

    $ActionNormalized = ($Action.Trim().ToLowerInvariant())

    switch ($ActionNormalized) {
        'install' {
            if (Test-CloudRadialInstalled) {
                Write-Log "CloudRadial service '$ServiceName' already present. Skipping install."
                break
            }

            Get-File -Url $CloudRadialDataAgent -OutFile $InstallerPath

            $InstallArgs = "/verysilent /companyid=$CompanyID"
            if ($SecurityKey -and $SecurityKey.Trim().Length -gt 0) {
                $InstallArgs += " /securitykey=$SecurityKey"
            }

            $code = Invoke-Installer -FilePath $InstallerPath -Arguments $InstallArgs -DisplayName "Installer"

            Start-Sleep -Seconds 8

            if (Test-CloudRadialInstalled) {
                if ($code -eq 3010) {
                    Write-Log "Install completed successfully (reboot required)."
                } else {
                    Write-Log "Install completed successfully."
                }
            } else {
                throw "Install finished but Windows service '$ServiceName' was not detected."
            }
        }

        'remove' {
            if (-not (Test-Path $UninstallerExe)) {
                Write-Log "Uninstaller not found at: $UninstallerExe"
                Write-Log "Nothing to uninstall (or path differs on this device)."
                break
            }

            $code = Invoke-Installer -FilePath $UninstallerExe -Arguments $UninstallArgs -DisplayName "Uninstaller"

            Start-Sleep -Seconds 5
            if (Test-CloudRadialInstalled) {
                Write-Log "Uninstall ran, but service '$ServiceName' still appears present."
            } else {
                if ($code -eq 3010) {
                    Write-Log "Uninstall completed successfully (reboot required)."
                } else {
                    Write-Log "Uninstall completed successfully."
                }
            }
        }

        default {
            throw "Invalid Action '$Action'. Use 'install' or 'remove'."
        }
    }

    Write-Log "======== Script end (success) ========"
}
catch {
    Write-Log "======== Script end (error) ========"
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
}
