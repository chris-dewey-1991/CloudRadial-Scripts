<#
.NOTES
===========================================================================
Name:           Manage-CloudRadial-Agents
Created by:     Chris Dewey
Updated:        2026.01.08
Version:        2.0
Status:         Active/Development
Changes:
    v2.0 2026.01.08 - Merged DesktopTray + DataAgent into one script; unified logging/downloads; per-agent install/remove
    v1.1 2026.01.08 - (prior) DesktopTray reliability + uninstall support; DataAgent action handling + service verification
    v1.0 2026.01.07 - (prior) Initial versions
===========================================================================
.DESCRIPTION
    Installs or removes CloudRadial components:
      - Desktop Tray Agent
      - Data Agent

    Choose both an Action and a Target:
      Action: Install | Remove
      Target: DesktopTray | DataAgent | Both

    Install:
      - Downloads installer(s) to C:\Source\ScriptFiles
      - Runs installer(s) silently

    Remove:
      - Runs known uninstaller(s) silently if present

    Notes:
      - Data Agent install can include /companyid and optional /securitykey
      - Data Agent checks for Windows service "CloudRadial" to confirm install
#>

# =========================
# USER CONTROLS (EDIT HERE)
# =========================
$Action = 'Install'            # Install | Remove
$Target = 'Both'               # DesktopTray | DataAgent | Both

# ---- Desktop Tray Agent ----
$CloudRadialDesktopTrayUrl = "[URL to CloudRadial Desktop Tray Agent installer]"
$DesktopTrayUninstallerExe = "C:\Program Files (x86)\[You Client Portal Directory]\unins000.exe"
$DesktopTrayUninstallArgs  = "/norestart /verysilent"
$DesktopTrayInstallArgs    = "/verysilent logging=true"

# ---- Data Agent ----
$CloudRadialDataAgentUrl   = "[URL to CloudRadial DataAgent installer]"
$CompanyID                 = "[CompanyID]"

# Optional Security Key (leave blank if not enabled)
$SecurityKey               = "[SecurityKey -if used]"

$DataAgentUninstallerExe   = "C:\Program Files (x86)\CloudRadial Agent\unins000.exe"
$DataAgentUninstallArgs    = "/norestart /verysilent"

# Service detection name (per CloudRadial recommendation)
$DataAgentServiceName      = "CloudRadial"

# =========================
# DO NOT EDIT BELOW
# =========================

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Paths
$SourcePath      = "C:\Source"
$ScriptFilesPath = Join-Path -Path $SourcePath -ChildPath "ScriptFiles"
$LogPath         = Join-Path -Path $SourcePath -ChildPath "NetPrimates-Logs"
$LogFile         = Join-Path -Path $LogPath -ChildPath "CloudRadial-Agents.log"

# Static, safe installer filenames
$DesktopTrayInstallerPath = Join-Path -Path $ScriptFilesPath -ChildPath "CloudRadialDesktopTrayAgent.exe"
$DataAgentInstallerPath   = Join-Path -Path $ScriptFilesPath -ChildPath "CloudRadialDataAgent.exe"

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

function Invoke-Exe {
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

function Test-CloudRadialDataAgentInstalled {
    return [bool](Get-Service -Name $DataAgentServiceName -ErrorAction SilentlyContinue)
}

function Convert-Action {
    param([Parameter(Mandatory)][string]$Value)

    $v = $Value.Trim().ToLowerInvariant()
    switch ($v) {
        'install' { return 'Install' }
        'remove'  { return 'Remove' }
        'uninstall' { return 'Remove' }
        default { throw "Invalid Action '$Value'. Use Install or Remove." }
    }
}

function Convert-Target {
    param([Parameter(Mandatory)][string]$Value)

    $v = $Value.Trim().ToLowerInvariant()
    switch ($v) {
        'desktoptray' { return 'DesktopTray' }
        'tray'        { return 'DesktopTray' }
        'dataagent'   { return 'DataAgent' }
        'agent'       { return 'DataAgent' }
        'both'        { return 'Both' }
        default { throw "Invalid Target '$Value'. Use DesktopTray, DataAgent, or Both." }
    }
}

function Install-DesktopTray {
    Write-Log "---- DesktopTray: Install start ----"
    Get-File -Url $CloudRadialDesktopTrayUrl -OutFile $DesktopTrayInstallerPath
    $code = Invoke-Exe -FilePath $DesktopTrayInstallerPath -Arguments $DesktopTrayInstallArgs -DisplayName "DesktopTray Installer"

    if ($code -eq 3010) { Write-Log "DesktopTray install completed successfully (reboot required)." }
    else { Write-Log "DesktopTray install completed successfully." }

    Write-Log "---- DesktopTray: Install end ----"
}

function Remove-DesktopTray {
    Write-Log "---- DesktopTray: Remove start ----"
    if (-not (Test-Path $DesktopTrayUninstallerExe)) {
        Write-Log "DesktopTray uninstaller not found at: $DesktopTrayUninstallerExe"
        Write-Log "Nothing to uninstall (or path differs on this device)."
        Write-Log "---- DesktopTray: Remove end ----"
        return
    }

    $code = Invoke-Exe -FilePath $DesktopTrayUninstallerExe -Arguments $DesktopTrayUninstallArgs -DisplayName "DesktopTray Uninstaller"

    if ($code -eq 3010) { Write-Log "DesktopTray uninstall completed successfully (reboot required)." }
    else { Write-Log "DesktopTray uninstall completed successfully." }

    Write-Log "---- DesktopTray: Remove end ----"
}

function Install-DataAgent {
    Write-Log "---- DataAgent: Install start ----"

    if (Test-CloudRadialDataAgentInstalled) {
        Write-Log "CloudRadial service '$DataAgentServiceName' already present. Skipping DataAgent install."
        Write-Log "---- DataAgent: Install end ----"
        return
    }

    Get-File -Url $CloudRadialDataAgentUrl -OutFile $DataAgentInstallerPath

    $installArgs = "/verysilent /companyid=$CompanyID"
    if ($SecurityKey -and $SecurityKey.Trim().Length -gt 0) {
        $installArgs += " /securitykey=$SecurityKey"
    }

    $code = Invoke-Exe -FilePath $DataAgentInstallerPath -Arguments $installArgs -DisplayName "DataAgent Installer"

    Start-Sleep -Seconds 8

    if (Test-CloudRadialDataAgentInstalled) {
        if ($code -eq 3010) { Write-Log "DataAgent install completed successfully (reboot required)." }
        else { Write-Log "DataAgent install completed successfully." }
    } else {
        throw "DataAgent install finished but Windows service '$DataAgentServiceName' was not detected."
    }

    Write-Log "---- DataAgent: Install end ----"
}

function Remove-DataAgent {
    Write-Log "---- DataAgent: Remove start ----"

    if (-not (Test-Path $DataAgentUninstallerExe)) {
        Write-Log "DataAgent uninstaller not found at: $DataAgentUninstallerExe"
        Write-Log "Nothing to uninstall (or path differs on this device)."
        Write-Log "---- DataAgent: Remove end ----"
        return
    }

    $code = Invoke-Exe -FilePath $DataAgentUninstallerExe -Arguments $DataAgentUninstallArgs -DisplayName "DataAgent Uninstaller"

    Start-Sleep -Seconds 5

    if (Test-CloudRadialDataAgentInstalled) {
        Write-Log "DataAgent uninstall ran, but service '$DataAgentServiceName' still appears present."
    } else {
        if ($code -eq 3010) { Write-Log "DataAgent uninstall completed successfully (reboot required)." }
        else { Write-Log "DataAgent uninstall completed successfully." }
    }

    Write-Log "---- DataAgent: Remove end ----"
}

# =========================
# MAIN
# =========================

try {
    Write-Log "======== Script start ========"
    $ActionNorm = Convert-Action -Value $Action
    $TargetNorm = Convert-Target -Value $Target

    Write-Log "Action: $ActionNorm"
    Write-Log "Target: $TargetNorm"
    Write-Log "Log:    $LogFile"

    switch ($ActionNorm) {
        'Install' {
            switch ($TargetNorm) {
                'DesktopTray' { Install-DesktopTray }
                'DataAgent'   { Install-DataAgent }
                'Both'        { Install-DesktopTray; Install-DataAgent }
            }
        }
        'Remove' {
            switch ($TargetNorm) {
                'DesktopTray' { Remove-DesktopTray }
                'DataAgent'   { Remove-DataAgent }
                'Both'        { Remove-DesktopTray; Remove-DataAgent }
            }
        }
        default { throw "Invalid action state: $ActionNorm" }
    }

    Write-Log "======== Script end (success) ========"
}
catch {
    Write-Log "======== Script end (error) ========"
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
}

