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

### Auto Increase Premium File Share Quota

When Azure Files Premium is selected for FSLogix Storage, this feature is deployed automatically. This tool helps reduce cost by scaling the file share quota only when needed. To benefit from the cost savings, select 100GB for your initial file share size.  For the first 500GB, the share will scale up 100 GB when only 50GB of quota remains.  Once the share has reached 500GB, the tool will scale up 500GB if less than 500GB of the quota remains.

**Reference:** [Azure Samples - GitHub Repository](https://github.com/Azure-Samples/azure-files-samples/tree/master/autogrow-PFS-quota)

**Deployed Resources:**

- Logic App
- Automation Account
  - Runbook
  - Webhook
  - Variable
