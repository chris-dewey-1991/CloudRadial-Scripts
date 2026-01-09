# Manage CloudRadial Desktop Tray Agent (PowerShell)

![powershell](https://img.shields.io/badge/Powershell-5.1%2B-blue)
![platform](https://img.shields.io/badge/Platform-Windows-lightgrey)
![version](https://img.shields.io/badge/Version-v1.1-purple)
![license](https://img.shields.io/badge/License-MIT-green)

A PowerShell script to **install or remove the CloudRadial Desktop Tray Agent** silently on Windows devices.  
Designed for **enterprise, MSP, Intune, and RMM deployments** with robust logging and error handling.

---

## Overview

`Manage-CloudRadial-DesktopTray` provides a reliable way to deploy or remove the CloudRadial Desktop Tray Agent.

### Install
- Downloads the installer to `C:\Source\ScriptFiles`
- Runs the installer silently
- Logs all actions and exit codes

### Remove
- Executes the known CloudRadial uninstaller silently (if present)
- Handles missing uninstall paths gracefully
- Logs all actions and exit codes

---

## Features

- Silent install and uninstall
- TLS-hardened downloads (TLS 1.2+)
- Download validation (size checks)
- Detailed timestamped logging
- Safe to re-run
- Intune / RMM friendly

---

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or later
- Administrator privileges
- Internet access to download the CloudRadial installer

---

## Configuration

Edit the **USER CONTROLS** section at the top of the script before deployment:

```powershell
$Action = 'Install'      # Install | Remove

$CloudRadialDesktopTray = "https://your-download-url/CloudRadialDesktopTrayAgent.exe"

$UninstallerExe = "C:\Program Files (x86)\<Client Portal Directory>\unins000.exe"
$UninstallArgs  = "/norestart /verysilent"

