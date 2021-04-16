# DNS Forwarders solution

## Assumptions

## Prerequisites

## ARM Template Parameters

<details>
<summary>Click to expand</summary>

- **AvSetName**: The name of the availability set.
- **DiskNamePrefix**: The name prefix for the disks on the virtual machines. A number will be added as a suffix based on the copy loop number.
- **DiskSku**: Storage SKU for the disks on the virtual machines.
- **DnsForwarderIPAddress**: Forwarder IP Address for the DNS servers.
- **DomainName**: The domain name used to join virtual machines to the domain.
- **DomainPassword**: Password for the privileged account to domain join virtual machines.
- **DomainUsername**: Username for the privileged account to domain join virtual machines.
- **HybridUseBenefit**: Conditionally deploys the VM with the Hybrid Use Benefit for Windows Server.
- **ImageOffer**: The offer of the OS image to use for the virtual machine resource.
- **ImagePublisher**: The publisher of the OS image to use for the virtual machine resource.
- **ImageSku**: The sku of the OS image to use for the virtual machine resource.
- **ImageVersion**: The version of the OS image to use for the virtual machine resource.
- **IPAddresses**: IP addresses for the DNS servers.
- **Location**: Location to deploy the Azure resources.
- **NicNamePrefix**: Name prefix for the NIC's on the virtual machines. A number will be added as a suffix based on the copy loop number.
- **SubnetId**: The resource ID for the subnet of the DNS servers.
- **Timestamp**: The timestamp is used to rerun VM extensions when the template needs to be redeployed due to an error or update.
- **VmNamePrefix**: Name prefix for the virtual machines.  A number will be added as a suffix based on the copy loop number.
- **VmPassword**: The local administrator password for virtual machines.
- **VmSize**: The size of the virtual machine.
- **VmUsername**: The local administrator username for virtual machines.

</details>

## Deployment Options

### Try with Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2FdnsForwarders%2Ftemplate.json)
[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2FdnsForwarders%2Ftemplate.json)

### Try with PowerShell

````powershell
New-AzResourceGroupDeployment `
    -ResourceGroupName '<Resource Group Name>' `
    -TemplateUri '<Template URI>'
````

### Try with CLI

````cli
az deployment group create \
    --resource-group '<Resource Group Name>' \
    --template-uri '<Template URI>>' \
    --parameters \
        AvSetName '<Availability Set Name>'
````
