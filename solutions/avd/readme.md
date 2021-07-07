# Azure Virtual Desktop solution

This solution will deploy Azure Virtual Desktop in an Azure subscription.  Depending on the options selected, either a personal or pooled host pool can be deployed with this solution.  The pooled option will deploy an App Group with a role assignment and deploy most of the requirements for FSLogix. There is one manual task for a pooled host pool that must be completed post deployment, a role assignment on the file share.  It does not work in an ARM Template, whether using a role assignment resource or a deployment script.  

This solution contains many features that are usually enabled manually after deploying a AVD host pool.  Those features are:

- Teams: installs the application and configures media optimization.
- FSLogix:
  - Configures the recommended registry settings on the session hosts.
  - Deploys an Azure File Share, domain joins the Storage Account, and sets the NTFS permissions.
- Start VM On Connect: configures the feature for the AVD host pool.
- VDI Optimization Script: this script will remove unnecessary apps, services, and processes from your Windows 10 OS, improving performance and resource utilization.
- AVD Monitoring Solution:
  - Deploys the Log Analytics Workspace with the required Windows Events and Performance Counters.
  - Deploys the Microsoft Monitoring Agent on session hosts.
  - Deploys diagnostic settings on the AVD host pool and workspace.
- Graphics drivers: if deploying an AVD appropriate VM SKU that supports a GPU, the required extension containing the graphics driver will be deployed automatically.

To successfully deploy this solution, you will need to ensure your scenario matches the assumptions below and you will need to complete the prerequisites.

## Assumptions

- Acquired the appropriate licensing for the operating system
- Landing zone deployed in Azure:
  - Virtual network and subnet(s)
  - ADDS synchronized with Azure AD
- Domain Controllers are deployed in the same Azure subscription that will be targeted for this AVD solution.  This is only required for a pooled scenario so the Azure Storage Account can be domain joined using the Custom Script Extension (this requirement will not be necessary in a future release).

## Prerequisites

- Create a Security Group in ADDS for your AVD users.  Once the object has synchronized to Azure AD, make note of the name and object ID in Azure AD.  This will be needed to deploy the solution.

## ARM Template Parameters

<details>
<summary>Click to expand</summary>

- **AppGroupName**: The name of the AVD application group.
- **AppGroupType**: The type of the AVD application group.
- **AvailabilitySetName**: The name for the Availability Set for the AVD Session Hosts.
- **CustomRdpProperty**: The RDP properties to add or remove RDP functionality on the AVD host pool. [Settings reference](https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/rdp-files?context=/azure/virtual-desktop/context/context).
- **DiskNamePrefix**: The name for the OS disk on the AVD session hosts.
- **DiskSku**: The storage SKU for the AVD session host disks.
- **DomainAdminPassword**: The domain administrator password to join the AVD session hosts to your domain
- **DomainAdminUsername**: The domain administrator username to join the AVD session hosts to your domain. Only the username is required. Do not add the NETBIOS value.
- **DomainControllerName**: The name of a Domain Controller in Azure for joining the Azure Storage Account to the domain.
- **DomainControllerResourceGroupName**: The resource group name of a Domain Controller in Azure for joining the Azure Storage Account to the domain.
- **DomainName**: The name of the domain that provides ADDS to the AVD session hosts and is synchronized with Azure AD.
- **FileShareQuota**: The quota for the Azure file share.  It's recommended to allocate 30GB per user.
- **HostPoolName**: The name for the AVD host pool.
- **HostPoolType**: These options specify the host pool type and depending on the type, provides the load balancing options or assignment types.
- **ImageOffer**: Offer for the virtual machine image
- **ImagePublisher**: Publisher for the virtual machine image
- **ImageSku**: SKU for the virtual machine image
- **ImageVersion**: Version for the virtual machine image
- **KerberosEncryptionType**: The Active Directory computer object Kerberos encryption type for the Azure Storage Account.
- **Location**: The deployment location for all the resources in this template.
- **MaxSessionLimit**: The maximum number of sessions per AVD session host.
- **newOrExisting**: This value determines if you are deploying the whole solution or redeploying to add session hosts to the host pool.
- **NicNamePrefix**: The name prefix for the Network Interfaces on the Session Hosts.  During deployment a 3 digit number will be added to each NIC to complete the name.
- **Optimizations**: The AVD optimizations to implement on the Session Hosts using the optimization script. Input a string array with any of the following values: 'All','WindowsMediaPlayer','AppxPackages','ScheduledTasks','DefaultUserSettings','Autologgers','Services','NetworkOptimizations','LGPO','DiskCleanup'.
- **OuPath**: The distinguished name for the target Organization Unit in Active Directory Domain Services. Leave blank for the Computers OU. Example: OU=Pooled,OU=AVD, DC=jasonmasten,DC=com.
- **PreferredAppGroupType**: The type of preferred application group type.  The default is Desktop which creates 'Desktop Application Group'
- **ResourceGroups**: The names of the resource groups for the AVD Host Pool and Session Hosts.  The first resource group will be dedicated to the AVD infrastructure.  The second resource group will be dedicated to the AVD session hosts.
- **SecurityPrincipalId**: The Object ID for the Security Principal to assign to the AVD Application Group.  This Security Principal will be assigned the Desktop Virtualization User role on the Application Group.
- **SecurityPrincipalName**: The name for the Security Principal to assign NTFS permissions on the Azure File Share to support FSLogix.  Any value can be input in this field if performing a deployment update or choosing a personal host pool.
- **SessionHostCount**: The number of session hosts to deploy in the AVD host pool
- **SessionHostIndex**: The session host number to begin with for the deployment. This is important when adding VM's to ensure the names do not conflict.
- **StartVmOnConnect**: Enable the 'Start VM On Connect' feature. [Reference](https://docs.microsoft.com/en-us/azure/virtual-desktop/start-virtual-machine-connect).
- **StorageAccountName**: The name for the Azure storage account containing the AVD user profile data.
- **StorageAccountSku**: The SKU for the Azure storage account containing the AVD user profile data.
- **Subnet**: The subnet for the AVD session hosts.
- **Tags**: Key / value pairs of metadata for the Azure resources.
- **Timestamp**: This value is used to rerun the DSC and Domain Join extensions when the template needs to be redeployed due to an error.
- **ValidationEnvironment**: The value determines whether the host pool should receive early AVD updates for testing.
- **VirtualNetwork**: Virtual network for the AVD sessions hosts
- **VirtualNetworkResourceGroup**: Virtual network resource group for the AVD sessions hosts
- **VmNamePrefix**: The name prefix for the AVD session hosts.  During deployment a 3 digit number will be added to each session host to complete the name.
- **VmPassword**: The local administrator password for the AVD session hosts.
- **VmSize**: The VM SKU for the AVD session hosts.
- **VmUsername**: The local administrator username for the AVD session hosts.
- **WvdObjectId**: The Object ID for the "Windows Virtual Desktop" Enterprise Application in Azure AD.  The Object ID can found by selecting 'Microsoft Applications' using the 'Application type' filter in the Enterprise Applications blade of Azure AD.

</details>

## Deployment Options

### Try with Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2Favd%2Fsolution.json)
[![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2Favd%2Fsolution.json)

### Try with PowerShell

````powershell
New-AzDeployment `
    -Location '<Azure location>' `
    -TemplateFile 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/avd/solution.json' `
    -Verbose
````

### Try with CLI

````cli
az deployment sub create \
    --location '<Azure location>' \
    --template-uri 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/avd/solution.json'
````
