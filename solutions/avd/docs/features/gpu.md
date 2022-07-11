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

### GPU Drivers & Settings

When an appropriate VM size (Nv, Nvv3, Nvv4, or NCasT4_v3 series) is selected, this solution will automatically deploy the appropriate virtual machine extension to install the graphics driver and configure the recommended registry settings.

**Reference:** [Configure GPU Acceleration - Microsoft Docs](https://docs.microsoft.com/en-us/azure/virtual-desktop/configure-vm-gpu)

**Deployed Resources:**

- Virtual Machines Extensions
  - AmdGpuDriverWindows
  - NvidiaGpuDriverWindows
  - CustomScriptExtension
