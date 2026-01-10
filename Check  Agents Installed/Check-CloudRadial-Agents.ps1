<#
.NOTES
===========================================================================
Name:           Check-CloudRadial-Agents
Created by:     Chris Dewey at Net Primates
Updated:        2026.01.08
Version:        1.0
Status:         Active/Development
Changes:
    v1.0 2026.01.07 - (prior) Initial versions
===========================================================================
.DESCRIPTION
    This script checks for the presence and status of CloudRadial-related
    applications, folders, and services on a Windows machine.
#>

# =========================
# CHANGEABLE SETTINGS
# =========================

# If system just booted, skip the whole check (helps avoid false negatives)
$MinUptimeMinutesToRun = 10

# Apps to check (exact DisplayName match in uninstall registry keys)
$InstalledAppNames = @(
    '[Client Portal Directory/Support Portal Name]',
    'CloudRadial Agent'
)

# Folders to check
$FoldersToCheck = @(
    'C:\Program Files (x86)\CloudRadial Agent',
    'C:\Program Files (x86)\[You Client Portal Directory]'
)

# Service check settings
# - First try exact name ($TargetServiceNameExact)
# - If not found, try wildcard matching ($ServiceNameWildcard and $ServiceDisplayNameWildcard)
$TargetServiceNameExact      = 'CloudRadial'
$ServiceNameWildcard         = 'CloudRadial*'
$ServiceDisplayNameWildcard  = 'CloudRadial*'

# =========================
# SCRIPT LOGIC
# =========================

# —–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# If system just booted, skip the whole check (helps avoid false negatives)
$bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptime  = (Get-Date) - $bootTime
if ($uptime.TotalMinutes -lt $MinUptimeMinutesToRun) {
    Write-Output "[INFO] System uptime is only $([int]$uptime.TotalMinutes) minutes. Skipping checks to avoid false negatives. Allowing $MinUptimeMinutesToRun minutes."
    exit 0
}
# —–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

function Get-InstalledAppByNameExact {
    param(
        [Parameter(Mandatory)]
        [string]$DisplayNameExact
    )

    $paths = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    foreach ($path in $paths) {
        try {
            $items = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -eq $DisplayNameExact }

            foreach ($i in $items) { $i }
        } catch {
            # ignore inaccessible paths
        }
    }
}

function Add-Result {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][bool]$Passed,
        [string]$Details = ''
    )

    $script:Results += [pscustomobject]@{
        Check   = $Name
        Status  = if ($Passed) { 'PASS' } else { 'FAIL' }
        Details = $Details
    }

    if ($Passed) {
        if ($Details) { Write-Output "[OK] $Name $Details" } else { Write-Output "[OK] $Name" }
    } else {
        if ($Details) { Write-Output "[ERROR] $Name $Details" } else { Write-Output "[ERROR] $Name" }
    }
}

$Results = @()

# -------------------------
# 1) Installed Applications
# -------------------------
foreach ($appName in $InstalledAppNames) {
    $app = Get-InstalledAppByNameExact -DisplayNameExact $appName

    if ($app) {
        $details = "(Found: $($app.DisplayName))"
        $passed  = $true
    } else {
        $details = "(Not found in registry uninstall keys)"
        $passed  = $false
    }

    Add-Result -Name "Installed App: $appName" -Passed $passed -Details $details
}

# -------------------------
# 2) Folder Locations
# -------------------------
foreach ($folder in $FoldersToCheck) {
    $exists = Test-Path -Path $folder -PathType Container
    $details = if ($exists) { "(Present)" } else { "(Missing)" }
    Add-Result -Name "Folder Exists: $folder" -Passed $exists -Details $details
}

# -------------------------
# 3) Service Check
#    Exact OR best match like CloudRadial*
# -------------------------
$svc = Get-Service -Name $TargetServiceNameExact -ErrorAction SilentlyContinue

if (-not $svc) {
    $svc = Get-Service -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -like $ServiceNameWildcard -or $_.DisplayName -like $ServiceDisplayNameWildcard
        } |
        Select-Object -First 1
}

if (-not $svc) {
    Add-Result -Name "Service Present: $TargetServiceNameExact (or $ServiceNameWildcard)" -Passed $false -Details "(No matching service found)"
} else {
    Add-Result -Name "Service Present: $($svc.Name)" -Passed $true -Details "(DisplayName: $($svc.DisplayName))"

    $running = ($svc.Status -eq 'Running')
    Add-Result -Name "Service Running: $($svc.Name)" -Passed $running -Details "(Current status: $($svc.Status))"
}

# -------------------------
# Final Summary
# -------------------------
Write-Output ""
Write-Output "==================== SUMMARY ===================="
$Results | ForEach-Object {
    Write-Output ("{0,-60} {1,-5} {2}" -f $_.Check, $_.Status, $_.Details)
}
Write-Output "================================================="

$fails = $Results | Where-Object { $_.Status -eq 'FAIL' }

if ($fails.Count -eq 0) {
    Write-Output "[SUCCESS] All checks passed."
    #exit 0
} else {
    Write-Output "[FAILED] $($fails.Count) check(s) failed."
    #exit 2
}
