# Azure Virtual Desktop Solution

[**Home**](../readme.md) | [**Features**](./features.md) | [**Design**](./design.md) | [**Prerequisites**](./prerequisites.md) | [**Post Deployment**](./post.md) | [**Troubleshooting**](./troubleshooting.md)

## Prerequisites

To successfully deploy this solution, you will need to ensure the following prerequisites have been completed:

- Licenses: [supported operating system licenses](https://docs.microsoft.com/en-us/azure/virtual-desktop/overview#requirements)
- Landing Zone deployed:
  - Virtual network and subnet(s)
  - Domain services if you plan to domain or hybrid join the session hosts
- Azure permissions: ensure the principal deploying the solution has Owner rights on the subscription. This solution contains many role assignments at different scopes so the principal deploying this solution will need to be an Owner at the subscription scope for a successful deployment.
- Create a service or user principal to domain join the session hosts. (Azure AD DS & AD DS only)
  - For AD DS, ensure the principal has the following permissions
    - "Join the Domain" on the domain
    - "Create Computer" on the parent OU or domain
    - "Delete Computer" on the parent OU or domain
- Create a security group for your AVD users and if applicable (Azure AD DS & AD DS), ensure the principal has successfully synchronized.
- Azure Files for FSLogix:
  - If you plan to deploy Azure Files with a Service Endpoint, be sure the subnet for the sessions hosts has the "Azure Storage" service endpoint enabled on the subnet.
  - If you plan to deploy Azure Files with a Private Endpoint, ensure the [Private Endpoint Network Policy has been disabled](https://docs.microsoft.com/en-us/azure/private-link/disable-private-endpoint-network-policy). Otherwise, the private endpoint resource will fail to deploy.
- Azure NetApp Files for FSLogix:
  - [Register the resource provider](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-register)
  - [Delegate a subnet to Azure NetApp Files](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-delegate-subnet)
  - [Enable the shared AD feature](https://docs.microsoft.com/en-us/azure/azure-netapp-files/create-active-directory-connections#shared_ad): this feature is required if you plan to deploy more than one domain joined NetApp account in the same Azure subscription and region.  As of 1/31/2022, this feature is in "public preview" in Azure Cloud and not available in Azure US Government.
