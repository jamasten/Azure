# Azure Virtual Desktop Solution

[**Home**](../../readme.md) | [**Features**](../features.md) | [**Design**](../design.md) | [**Prerequisites**](../prerequisites.md) | [**Post Deployment**](../post.md) | [**Troubleshooting**](../troubleshooting.md)

## Features

- [**Auto Increase Premium File Share Quota**](./autoIncreasePremiumFileShareQuota.md)
- [**Backups**](./backups.md)
- [**BitLocker Encryption**](./bitlocker.md)
- [**Drain Mode**](./drainMode.md)
- [**Ephemeral OS Disks**](./ephemeralOsDisk.md)
- [**FSLogix**](./fslogix.md)
- [**GPU Drivers & Settings**](./gpu.md)
- [**High Availability**](./highAvailability.md)
- [**Monitoring**](./monitoring.md)
- [**RDP ShortPath for Managed Networks**](./rdpShortPath.md)
- [**Scaling Automation**](./scalingAutomation.md)
- [**Screen Capture Protection**](./screenCaptureProtection.md)
- [**Security Technical Implementation Guides (STIG)**](./securityTechnicalImplementationGuides.md)
- [**SMB Multichannel**](./smbMultiChannel.md)
- [**Start VM On Connect**](./startVmOnConnect.md)
- [**Validation**](./validation.md)
- [**Virtual Desktop Optimization Tool**](./virtualDesktopOptimizationTool.md)

### Ephemeral OS Disks

This optional feature deploys the session hosts so that the resource or cache disk on the virtual machine is used for the operating system. A disk resource will not be created. This is not a common scenario but it does provide cost savings for a solution that will either keep the session hosts online 24/7 or if you plan to delete the session hosts regularly.

**Reference:** [Ephemeral OS Disks - Microsoft Docs](https://docs.microsoft.com/en-us/azure/virtual-machines/ephemeral-os-disks)