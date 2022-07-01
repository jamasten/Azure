# Azure Virtual Desktop Solution

[**Home**](../readme.md) | [**Features**](./features.md) | [**Design**](./design.md) | [**Prerequisites**](./prerequisites.md) | [**Post Deployment**](./post.md) | [**Troubleshooting**](./troubleshooting.md)

## Post Deployment

Several resources are deployed with this solution that may be deleted once the deployment has completed.  These resources will exist in the "deployment" resource group:

- Deployment Script
- Disk
- Network Interface
- User Assigned Managed Identity
- Virtual Machine

You may purge the whole resource group.  If you decide to purge the resource group, you should also remove the orphaned role assignments on your subscription and storage account.  If you do not and attempt an update deployment on the solution, it will fail.
