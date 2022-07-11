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
- [**Validation**](./validation.md#validation)
- [**Virtual Desktop Optimization Tool**](./virtualDesktopOptimizationTool.md#virtual-desktop-optimization-tool-vdot)

### Ephemeral OS Disks

This optional feature deploys the session hosts so that the resource or cache disk on the virtual machine is used for the operating system. A disk resource will not be created. This is not a common scenario but it does provide cost savings for a solution that will either keep the session hosts online 24/7 or if you plan to delete the session hosts regularly.

**Reference:** [Ephemeral OS Disks - Microsoft Docs](https://docs.microsoft.com/en-us/azure/virtual-machines/ephemeral-os-disks)