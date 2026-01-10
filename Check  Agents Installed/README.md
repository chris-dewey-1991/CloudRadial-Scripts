# Check-CloudRadial-Agents

![powershell](https://img.shields.io/badge/Powershell-5.1%2B-blue)
![platform](https://img.shields.io/badge/Platform-Windows-lightgrey)
![version](https://img.shields.io/badge/Version-v1.1-purple)
![license](https://img.shields.io/badge/License-MIT-green)

A PowerShell health-check script used to validate the presence and runtime status of **CloudRadial-related applications, folders, and services** on Windows endpoints.

Developed by **Chris Dewey** for use in monitoring, RMM checks. This is used within our RMM to run a check every hour. If its not detected it runs the deployment scripts

---

## 📌 Overview

This script performs the following checks:

- Verifies required **CloudRadial applications** are installed
- Confirms required **folder paths** exist
- Detects the **CloudRadial service** and ensures it is running
- Skips execution on recently booted systems to avoid false negatives
- Outputs clear **PASS / FAIL** results with a final summary

It is safe to run repeatedly and does **not** modify system state.

---

## 🔍 What It Checks

### 1. Installed Applications

Checks for exact DisplayName matches in the Windows uninstall registry (both 32-bit and 64-bit keys):

- `Net Primates Limited Support Portal`
- `CloudRadial Agent`

---

### 2. Folder Presence

Confirms the existence of the following directories:

- `C:\Program Files (x86)\CloudRadial Agent`
- `C:\Program Files (x86)\Net Primates Limited Support Portal`

---

### 3. Service Status

- Attempts to locate a service named **`CloudRadial`**
- Falls back to wildcard matching (`CloudRadial*`) on:
  - Service Name
  - Display Name
- Confirms whether the service is **running**

---

### 4. Boot-Time Protection

To avoid false failures immediately after startup:

- The script **skips all checks** if system uptime is less than **10 minutes** (configurable)

---

## ⚙️ Configuration

All configurable values are centralized at the **top of the script** for easy customization:

```powershell
$MinUptimeMinutesToRun = 10

$InstalledAppNames = @(
    'Net Primates Limited Support Portal',
    'CloudRadial Agent'
)

$FoldersToCheck = @(
    'C:\Program Files (x86)\CloudRadial Agent',
    'C:\Program Files (x86)\Net Primates Limited Support Portal'
)

$TargetServiceNameExact      = 'CloudRadial'
$ServiceNameWildcard         = 'CloudRadial*'
$ServiceDisplayNameWildcard  = 'CloudRadial*'
