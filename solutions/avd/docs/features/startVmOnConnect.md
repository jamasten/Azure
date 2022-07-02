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

### Start VM On Connect

This optional feature allows your end users to turn on a session host when all the session hosts have been stopped / deallocated. This is done automatically when the end user opens the AVD client and attempts to access a resource.  Start VM On Connect and Scaling Automation compliment each other to ensure session hosts can be turned off when they are not needed but a session host can be made available when needed.

**Reference:** [Start VM On Connect - Microsoft Docs](https://docs.microsoft.com/en-us/azure/virtual-desktop/start-virtual-machine-connect?tabs=azure-portal)

**Deployed Resources:**

- Role Definition
- Role Assignment
- Host Pool
