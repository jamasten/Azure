# Azure Virtual Desktop Solution

[**Home**](../../readme.md) | [**Features**](../features.md) | [**Design**](../design.md) | [**Prerequisites**](../prerequisites.md) | [**Post Deployment**](../post.md) | [**Troubleshooting**](../troubleshooting.md)

## Features

- [**Auto Increase Premium File Share Quota**](./autoIncreasePremiumFileShareQuota.md#auto-increase-premium-file-share-quota)
- [**Backups**](./backups.md#backups)
- [**BitLocker Encryption**](./bitlocker.md#bitlocker-encryption)
- [**Drain Mode**](./drainMode.md#drain-mode)
- [**Ephemeral OS Disks**](./ephemeralOsDisk.md#ephemeral-os-disks)
- [**FSLogix**](./fslogix.md#fslogix)
- [**GPU Drivers & Settings**](./gpu.md#gpu-drivers--settings)
- [**High Availability**](./highAvailability.md#high-availability)
- [**Monitoring**](./monitoring.md#monitoring)
- [**RDP ShortPath for Managed Networks**](./rdpShortPath.md#rdp-shortpath-for-managed-networks)
- [**Scaling Automation**](./scalingAutomation.md#scaling-automation)
- [**Screen Capture Protection**](./screenCaptureProtection.md#screen-capture-protection)
- [**Security Technical Implementation Guides (STIG)**](./securityTechnicalImplementationGuides.md#security-technical-implementation-guides-stig)
- [**SMB Multichannel**](./smbMultiChannel.md#smb-multichannel)
- [**Start VM On Connect**](./startVmOnConnect.md#start-vm-on-connect)
- [**Trusted Launch**](./trustedLaunch.md#trusted-launch)
- [**Validation**](./validation.md#validation)
- [**Virtual Desktop Optimization Tool**](./virtualDesktopOptimizationTool.md#virtual-desktop-optimization-tool-vdot)

### Security Technical Implementation Guides (STIG)

This optional feature deploys the required resources to enforce and report on DISA STIG compliance. This is a common configuration for US federal government customers.

**Reference:** [](https://public.cyber.mil/stigs/)

**Deployed Resources:**

- Automation Account
  - Modules
  - Configuration
  - Compilation Job
- DSC extension
