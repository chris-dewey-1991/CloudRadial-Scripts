# CloudRadial Management Scripts (PowerShell)

![powershell](https://img.shields.io/badge/Powershell-5.1%2B-blue)
![platform](https://img.shields.io/badge/Platform-Windows-lightgrey)
![license](https://img.shields.io/badge/License-MIT-green)

A centralized collection of **PowerShell scripts for managing CloudRadial components** on Windows devices.

This repository is intended for **enterprise, MSP, and managed environments**, providing reliable automation for installing, removing, validating, and maintaining CloudRadial agents.

---

## Repository Purpose

The goal of this repository is to provide **production-ready PowerShell tooling** to manage the CloudRadial agent lifecycle in a consistent and repeatable way.

Scripts in this repository are designed to:
- Run silently with no user interaction
- Be safe to re-run (idempotent)
- Support both installation and removal scenarios
- Provide clear validation and error handling
- Produce detailed logs for troubleshooting and audit purposes

---

## Scope

This repository focuses on managing CloudRadial software components, including:
- Desktop-based user agents
- Background data collection agents
- Supporting validation and detection logic

It is designed to support the **full lifecycle** of CloudRadial deployments, from initial rollout through ongoing management and verification.

---

## Design Principles

All scripts in this repository follow the same core principles:

- **Silent execution**  
  Suitable for system-level deployment via MDM or RMM tools

- **Explicit actions**  
  Clear install, remove, and validation behavior

- **Robust logging**  
  Timestamped logs written locally for troubleshooting

- **Enterprise-friendly paths**  
  Consistent use of predictable directories

- **Defensive execution**  
  Validation of downloads, installers, services, and exit codes

---

## Environment & Deployment

These scripts are designed to be deployed using:

- Microsoft Intune (Win32 apps or remediations)
- RMM platforms
- Group Policy startup scripts
- Manual administrative execution

They are suitable for use in:
- Corporate environments
- MSP-managed tenants
- Hybrid and fully cloud-managed devices
