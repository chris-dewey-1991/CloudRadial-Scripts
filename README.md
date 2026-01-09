# CloudRadial Management Scripts (PowerShell)

![powershell](https://img.shields.io/badge/Powershell-5.1%2B-blue)
![platform](https://img.shields.io/badge/Platform-Windows-lightgrey)
![license](https://img.shields.io/badge/License-MIT-green)

A collection of **PowerShell scripts for managing CloudRadial components** on Windows devices, built for enterprise, MSP, Intune, and RMM deployments.

This repository provides scripts to **install, remove, manage, and validate** CloudRadial agents in a reliable, repeatable, and fully silent manner.

---

## Overview

These scripts manage the lifecycle of CloudRadial components, including:

- **CloudRadial Desktop Tray Agent**
- **CloudRadial Data Agent**
- Combined agent management
- Installation validation and health checks (detection script)

All scripts follow the same design principles:
- Silent execution
- Robust logging
- Safe re-runs (idempotent behavior)
- Explicit install and removal actions
- Enterprise-friendly paths and conventions

---

## Included Scripts

### 1. Manage-CloudRadial-DesktopTray.ps1
Installs or removes the **CloudRadial Desktop Tray Agent**.

**Capabilities**
- Silent install
- Silent uninstall
- Download validation
- Detailed logging

---

### 2. Manage-CloudRadial-DataAgent.ps1
Installs or removes the **CloudRadial Data Agent**.

**Capabilities**
- Silent install with `/companyid`
- Optional `/securitykey` support
- Windows service detection for validation
- Silent uninstall with verification

---

### 3. Manage-CloudRadial-Agents.ps1
A **unified script** that manages both CloudRadial agents.

**Capabilities**
- Install or remove:
  - Desktop Tray
  - Data Agent
  - Both
- Unified logging
- Per-agent targeting
- Service-based validation for Data Agent

---

### 4. Check-CloudRadial-Agents.ps1 (Coming Shortly)
A detection and validation script designed to **check the health and presence** of CloudRadial components.

**Planned Capabilities**
- Detect installed agents
- Verify Windows services
- Validate expected install state
- Return exit codes suitable for:
  - Intune detection rules
  - RMM health checks
  - Compliance reporting

> This script will be uploaded shortly and is intended to complement the install/remove scripts for full lifecycle management.

---

## Folder Structure

```text
CloudRadial/
├── Manage-CloudRadial-DesktopTray.ps1
├── Manage-CloudRadial-DataAgent.ps1
├── Manage-CloudRadial-Agents.ps1
├── Check-CloudRadial-Agents.ps1   (upcoming)
└── README.md
