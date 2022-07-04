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

### FSLogix

If selected, this solution will deploy the required resources and configurations so that FSLogix is fully configured and ready for immediate use post deployment. Only Azure AD DS and AD DS are supported with this solution. Azure AD support is in "Public Preview" and will added after it is "Generally Available". Azure Files and Azure NetApp Files are the only two SMB storage services available in this solution.  A management VM is deployed to facilitate the domain join of Azure Files (AD DS only) and configures the NTFS permissions on the share(s). Azure Files can be deployed with either a public endpoint, [service endpoint](https://docs.microsoft.com/en-us/azure/storage/files/storage-files-networking-overview#public-endpoint-firewall-settings), or [private endpoint](https://docs.microsoft.com/en-us/azure/storage/files/storage-files-networking-overview#private-endpoints). With this solution, FSLogix containers can be configured in multiple ways:

- Cloud Cache Profile Container
- Cloud Cache Profile & Office Container
- Profile Container
- Profile & Office Container

**Reference:** [FSLogix - Microsoft Docs](https://docs.microsoft.com/en-us/fslogix/overview)

**Deployed Resources:**

- Azure Storage Account (Optional)
  - File Services
  - Share(s)
- Azure NetApp Account (Optional)
  - Capacity Pool
  - Volume(s)
- Virtual Machine(s)
- Network Interface(s)
- Disk(s)
- Private Endpoint (Optional)
- Private DNS Zone (Optional)
