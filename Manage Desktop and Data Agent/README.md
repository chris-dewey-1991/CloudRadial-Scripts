# Manage CloudRadial Agents (PowerShell)

![powershell](https://img.shields.io/badge/Powershell-5.1%2B-blue)
![platform](https://img.shields.io/badge/Platform-Windows-lightgrey)
![version](https://img.shields.io/badge/Version-v2.0-purple)
![license](https://img.shields.io/badge/License-MIT-green)

A unified PowerShell script to **install or remove CloudRadial agents** on Windows devices, including:

- CloudRadial **Desktop Tray Agent**
- CloudRadial **Data Agent**

Built for **enterprise, MSP, Intune, and RMM deployments**, with robust logging, validation, and per-agent control.

---

## Overview

`Manage-CloudRadial-Agents` consolidates management of CloudRadial components into a single script.

You choose:
- **Action:** `Install` or `Remove`
- **Target:** `DesktopTray`, `DataAgent`, or `Both`

The script handles:
- Secure downloads
- Silent installs and removals
- Service detection for the Data Agent
- Detailed logging and error handling

---

## Features

- Single script for both CloudRadial agents
- Per-agent install or removal
- Silent execution (no user interaction)
- TLS 1.2+ hardened downloads
- Download validation and retry logic
- Windows service verification for Data Agent
- Safe to re-run
- Intune / RMM friendly

---

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or later
- Administrator privileges
- Internet access to CloudRadial installer URLs

---

## Configuration

Edit the **USER CONTROLS** section at the top of the script before deployment.

### Core Options

```powershell
$Action = 'Install'            # Install | Remove
$Target = 'Both'               # DesktopTray | DataAgent | Both

