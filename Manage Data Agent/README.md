# Manage CloudRadial Data Agent (PowerShell)

![powershell](https://img.shields.io/badge/Powershell-5.1%2B-blue)
![platform](https://img.shields.io/badge/Platform-Windows-lightgrey)
![version](https://img.shields.io/badge/Version-v1.1-purple)
![license](https://img.shields.io/badge/License-MIT-green)

A PowerShell script to **install or remove the CloudRadial Data Agent** silently on Windows devices, with built-in service detection, validation, and detailed logging.

Designed for **enterprise, MSP, Intune, and RMM deployments**.

---

## Overview

`Manage-CloudRadial-DataAgent` provides a safe and repeatable way to manage the CloudRadial Data Agent lifecycle.

### Install
- Downloads the installer to `C:\Source\ScriptFiles`
- Runs the installer silently
- Passes required `/companyid` and optional `/securitykey`
- Verifies installation by checking the Windows service

### Remove
- Runs the known uninstaller silently (if present)
- Verifies removal using service detection
- Handles missing uninstall paths gracefully

---

## Features

- Silent install and uninstall
- TLS 1.2+ hardened downloads
- Download validation (file size check)
- Windows service verification (`CloudRadial`)
- Detailed timestamped logging
- Safe to re-run
- Intune / RMM friendly

---

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or later
- Administrator privileges
- Internet access to download the Data Agent installer

---

## Configuration

Edit the **USER CONTROLS** section at the top of the script before deployment.

```powershell
$Action = 'install'      # install | remove

$CloudRadialDataAgent = "https://your-download-url/CloudRadialDataAgent.exe"
$CompanyID            = "<CompanyID provided by CloudRadial>"

# Optional
$SecurityKey          = "<Security Key provided by CloudRadial>"

$UninstallerExe = "C:\Program Files (x86)\CloudRadial Agent\unins000.exe"
$UninstallArgs  = "/norestart /verysilent"

