# Windows Virtual Desktop Rip & Replace Solution

This solution will create a new registration token on a WVD host pool and add new session hosts to a pooled or personal host pool.

## Assumptions

WVD has been deployed and you want to add session hosts to an existing host pool or do a rip and replace for patch management.  This solution also assumes you are storing your template files on an Azure Storage account and requires a SAS token to access the files from a blob container.

## Prerequisites

WVD is deployed in an Azure Subscription.

## ARM Template Parameters

<details>
<summary>Click to expand</summary>

- **AvailabilitySetName**: The name for the Availability Set for the WVD Session Hosts.
- **CustomRdpProperty**: The RDP properties to add or remove RDP functionality on the host pool. [Settings reference](https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/rdp-files?context=/azure/virtual-desktop/context/context)
- **DiskNamePrefix**: The name for the OS disk on the Session Hosts.
- **DiskSku**: Storage SKU for the WVD session host disks.
- **DomainAdminPassword**: The account password to join the WVD session hosts to your domain.
- **DomainAdminUsername**: The account username to join the WVD session hosts to your domain.
- **DomainName**: Name of the domain that provides ADDS to the WVD session hosts and is synchronized with Azure AD
- **HostPoolType**: These options specify the host pool type and depending on the type, provides the load balancing options and assignment types.
- **ImageOffer**: Offer for the virtual machine image
- **ImagePublisher**: Publisher for the virtual machine image
- **ImageSku**: SKU for the virtual machine image
- **ImageVersion**: Version for the virtual machine image
- **Location**: Deployment location for all resources
- **MaxSessionLimit**: Maximum sessions per WVD session host
- **NicNamePrefix**: The Name Prefix for the Network Interfaces on the Session Hosts.  During deployment a 3 digit number will be added to each NIC to complete the name.
- **Optimizations**: WVD Optimizations to implement on the Session Hosts using the optimization script. Input a string array with any of the following values: 'All','WindowsMediaPlayer','AppxPackages','ScheduledTasks','DefaultUserSettings','Autologgers','Services','NetworkOptimizations','LGPO','DiskCleanup'.
- **OuPath**: Distinguished name for the target Organization Unit in Active Directory Domain Services.
- **PreferredAppGroupType**: The type of preferred application group type.  The default is Desktop which creates 'Desktop Application Group'
- **ResourceGroups**: The Names of the resource groups for the WVD Host Pool and Session Hosts.
- **SasToken**: SAS Token for linked template files in an Azure Storage Account.
- **SessionHostCount**: Number of session hosts to deploy in the host pool
- **SessionHostIndex**: The session host number to begin with for the deployment. This is important when adding VM's to ensure the names do not conflict.
- **Subnet**: Subnet for the WVD session hosts
- **Timestamp**: This value is used to rerun the DSC and Domain Join extensions when the template needs to be redeployed due to an error.
- **ValidationEnvironment**: The value determines whether the host pool should receive early WVD updates for testing.
- **VirtualNetwork**: Virtual network for the WVD sessions hosts
- **VirtualNetworkResourceGroup**: Virtual network resource group for the WVD sessions hosts
- **VmNamePrefix**: The Name Prefix for the Session Hosts.  During deployment a 3 digit number will be added to each Session Host to complete the name.
- **VmPassword**: Local administrator password for the WVD session hosts
- **VmSize**: Virtual machine SKU
- **VmUsername**: Local administrator username for the session hosts

</details>

## Deployment Options

### Try with Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2FavdRipReplace%2Fsolution.json)
[![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2FavdRipReplace%2Fsolution.json)

### Try with PowerShell

````powershell
New-AzSubscriptionDeployment `
    -Location <Azure location> `
    -TemplateUri 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/ripReplace/solution.json' `
    -Verbose
````

### Try with CLI

````cli
az deployment group create \
    --location '<Azure location>' \
    --template-uri 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/ripReplace/solution.json'
````
