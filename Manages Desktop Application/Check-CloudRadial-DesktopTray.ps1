# —–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# Net Primates Limited Support Portal - Check Script
# —–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# If system just booted, skip the whole check (helps avoid false negatives)
$bootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$uptime  = (Get-Date) - $bootTime
if ($uptime.TotalMinutes -lt 10) {
    Write-Output "[INFO] System uptime is only $([int]$uptime.TotalMinutes) minutes. Skipping checks to avoid false negatives. Allowing 10 minutes."
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
# 1) Installed Application
# -------------------------
$appName = 'Net Primates Limited Support Portal'

$app = Get-InstalledAppByNameExact -DisplayNameExact $appName
if ($app) {
    $appDetails = "(Found: $($app.DisplayName) $($app.DisplayVersion))"
    $appPassed  = $true
} else {
    $appDetails = "(Not found in registry uninstall keys)"
    $appPassed  = $false
}
Add-Result -Name "Installed App: $appName" -Passed $appPassed -Details $appDetails

# -------------------------
# 2) Folder Location
#    Check both Program Files (x86) and Program Files
# -------------------------
$folderCandidates = @(
    'C:\Program Files (x86)\Net Primates Limited Support Portal',
    'C:\Program Files\Net Primates Limited Support Portal'
)

$foundFolder = $folderCandidates | Where-Object { Test-Path -Path $_ -PathType Container } | Select-Object -First 1

if ($foundFolder) {
    Add-Result -Name "Folder Exists: Net Primates Limited Support Portal" -Passed $true -Details "(Found: $foundFolder)"
} else {
    Add-Result -Name "Folder Exists: Net Primates Limited Support Portal" -Passed $false -Details "(Not found in either Program Files or Program Files (x86))"
}

# -------------------------
# Final Summary
# -------------------------
Write-Output ""
Write-Output "========= Net Primates Support Portal ========="
$Results | ForEach-Object {
    Write-Output ("{0,-60} {1,-5} {2}" -f $_.Check, $_.Status, $_.Details)
}
Write-Output "================================================"

$fails = $Results | Where-Object { $_.Status -eq 'FAIL' }

if ($fails.Count -eq 0) {
    Write-Output "[SUCCESS] Net Primates Limited Support Portal is installed."
    #exit 0
} else {
    Write-Output "[FAILED] $($fails.Count) check(s) failed."
    #exit 2
}
