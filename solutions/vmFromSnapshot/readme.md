# Virtual Machine from Azure Snapshot Solution

This solution will create a new Azure virtual machine using an Azure snapshot.

## Assumptions

The following resources should already exist in your Azure subscription before deploying this ARM template:

- Virtual Network
- Snapshot

## ARM Template Parameters

<details>
<summary>Click to expand</summary>

- **DiskSku**: The disk sku for the virtual machine operating system disk.
- **HyperVGeneration**: The HyperV generation of the virtual machine.
- **LicenseType**: The license type or hybrid use benefit for the virtual machine operating system.
- **Location**: The deployment location for all the resources in this template.
- **OsType**: The operating system type for the virtual machine.
- **PublicIpAddress**: This setting determines whether a Public IP Address will be deployed.
- **SnapshotResourceId**: The resource ID of the snapshot for the virtual machine.
- **SubnetName**: The name of the subnet for virtual machine's network interface.
- **ResourceNameSuffix**: The suffix for all the names of resources that are deployed with this template.
- **VirtualMachineSize**: The size or sku for the virtual machine.
- **VnetName**: The name of the virtual network for the virtual machine's network interface.
- **VnetResourceGroupName**: The resource group name of the virtual network for the virtual machine's network interface.

</details>

## Deployment Options

### Try with Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2FvmFromSnapshot%2Fsolution.json)
[![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2FvmFromSnapshot%2Fsolution.json)

### Try with PowerShell

```powershell
New-AzResourceGroupDeployment `
    -ResourceGroupName '<Azure Resource Group>' `
    -TemplateUri 'https://raw.githubusercontent.com/battelle-cube/azure-avd-automation/main/solutions/vmFromSnapshot/solution.json'
```

### Try with CLI

````cli
az deployment group create \
    --resource-group '<Azure Resource Group>' \
    --template-uri 'https://raw.githubusercontent.com/battelle-cube/azure-avd-automation/main/solutions/vmFromSnapshot/solution.json'
````
