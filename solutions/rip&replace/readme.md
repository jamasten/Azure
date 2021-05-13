# Windows Virtual Desktop Rip & Replace Solution

This solution will ...

## Assumptions

WVD has been deployed and you want to add additional session hosts to a host pool or do a rip and replace for patch management.

## Prerequisites

WVD is deployed in an Azure Subscription.

## ARM Template Parameters

<details>
<summary>Click to expand</summary>

### REQUIRED

- **AppGroupName**: The name of the WVD application group
- **AppGroupType**: The type of the WVD application group
- **DiskSku**: Storage SKU for the WVD session host disks
- **DomainAbbreviation**: An abbreviation for your domain or organization to uniquely name your Azure Storage Accounts across all of Azure.
- **DomainName**: Name of the domain that provides ADDS to the WVD session hosts and is synchronized with Azure AD
- **DomainAdminPassword**: Input your domain administrator password to join the WVD session hosts to your domain
- **DomainAdminUsername**: Input your domain administrator username to join the WVD session hosts to your domain. Only the username is required. Do not add the NETBIOS value.
- **Environment**: The environment for the deployed resources. Default is 'd' for 'Development'. 'p' is for 'Production'. 't' is for 'Test'.
- **FileShareQuota**: The quota for the Azure file share.  It's recommended to allocate 30GB per user.
- **HostPoolType**: These options specify the host pool type and depending on the type, provides the load balancing options and assignment types.
- **Identifier**: Unique value to define the purpose of this solution. This will be used in resource naming and added as a tag to each resource.
- **ImageOffer**: Offer for the virtual machine image
- **ImagePublisher**: Publisher for the virtual machine image
- **ImageSku**: SKU for the virtual machine image
- **ImageVersion**: Version for the virtual machine image
- **Location**: Deployment location for all resources
- **MaxSessionLimit**: Maximum sessions per WVD session host
- **newOrExisting**: This value determines if you are deploying the whole solution or redeploying to add session hosts to the host pool.
- **Ordinal**: Deployment number for WVD; determines which project or group this falls under
- **PreferredAppGroupType**: The type of preferred application group type.  The default is Desktop which creates 'Desktop Application Group'
- **SecurityPrincipalId**: The Object ID for the Security Principal to assign to the WVD Application Group.  This Security Principal will be assigned the Desktop Virtualization User role on the Application Group.
- **SessionHostCount**: Number of session hosts to deploy in the host pool
- **SessionHostIndex**: The session host number to begin with for the deployment. This is important when adding VM's to ensure the names do not conflict.
- **StorageAccountSku**: Storage SKU for the WVD session host disks
- **Subnet**: Subnet for the WVD session hosts
- **ValidationEnvironment**: The value determines whether the host pool should receive early WVD updates for testing.
- **VirtualNetwork**: Virtual network for the WVD sessions hosts
- **VirtualNetworkResourceGroup**: Virtual network resource group for the WVD sessions hosts
- **VmPassword**: Local administrator password for the WVD session hosts
- **VmSize**: Virtual machine SKU
- **VmUsername**: Local administrator username for the session hosts

### OPTIONAL

- **Classification**: The data classification for the WVD resources.  This will be added to a tag for each resource.
- **CriticalityLevel**: Number defining the criticality of the WVD solution.
- **CustomRdpProperty**: The RDP properties to add or remove RDP functionality on the host pool. [Settings reference](https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/rdp-files?context=/azure/virtual-desktop/context/context)
- **Department**: The department within your organization owning this WVD solution. This will be added to a tag for each resource.
- **OuPath**: Distinguished name for the target Organization Unit in Active Directory Domain Services. Leave blank for the Computers OU. Example: OU=Pooled,OU=WV- DC=jasonmasten,DC=com**
- **Owner**: Name of the person responsible for this solution.  This will be added to a tag for each resource.
- **Project**: Input the project associated with this WVD solution.  This will be added to a tag for each resource.
- **Region**: Input the region of your office.  This will be added to a tag for each resource
- **Timestamp**: This value is used to rerun the DSC and Domain Join extensions when the template needs to be redeployed due to an error.

</details>

## Deployment Options

### Try with Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2Fwvd%2Fsolution.json)
[![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2Fwvd%2Fsolution.json)

### Try with PowerShell

````powershell
New-AzResourceGroupDeployment `
    -ResourceGroupName '<Resource Group Name>' `
    -TemplateFile 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/wvd/solution.json' `
    -AppGroupName '<WVD Application Group Name>' `
    -AppGroupType '<WVD Application Group Type>' `
    -Classification '<Solution Classification>' `
    -CriticalityLevel '<Solution Criticality Level>' `
    -CustomRdpProperty '<Custom RDP Properties for Host Pool>' `
    -Department '<Company, Organization, or Agency Department>' `
    -DiskSku '<VM Disk SKU>' `
    -DomainAbbreviation '<Domain Name Abbreviation for Storage Account Name>' `
    -DomainName '<Domain Name>' `
    -DomainAdminPassword '<Privileged account password to domain join virtual machines>' `
    -DomainAdminUsername '<Privileged account username to domain join virtual machines>'  `
    -Environment '<Solution lifecycle environment>' `
    -FileShareQuota '<File share quota for the FSLogix profiles>' `
    -HostPoolType '<Host Pool Type>' `
    -Identifier '<A value to identify the purpose of the deployment>' `
    -ImageOffer '<Offer for image resource>' `
    -ImagePublisher '<Publisher for image resource>' `
    -ImageSku '<SKU for image resource>' `
    -ImageVersion '<Version for image resource>' `
    -Location '<Deployment location for all resources>' `
    -MaxSessionLimit '<Host Pool Max Session Limit>' `
    -newOrExisting '<Deploy the full solution or add new session hosts>' `
    -Ordinal '<Integer to differentiate solution deployments per region>' `
    -OuPath '<Distinguished name of the target OU>' `
    -Owner '<Solution Owner>' `
    -PreferredAppGroupType '<Preferred WVD application group type>' `
    -Project '<Project Name for the WVD solution>' `
    -Region '<Company, Organization, or Agency regional location>' `
    -SecurityPrincipalId '<Azure AD Object ID for the security principal>' `
    -SessionHostCount '<Number of session hosts to deploy>' `
    -SessionHostIndex '<Number to start with for the session host name>' `
    -StorageAccountSku '<SKU for the Azure Storage Account>' `
    -Subnet '<Virtual Network Subnet for the sessions hosts>' `
    -Timestamp '<unique value to redeploying the DSC and Domain Join extensions>' `
    -ValidationEnvironment '<Host Pool Validation Environment>' `
    -VirtualNetwork '<Virtual Network for the session hosts>' `
    -VirtualNetworkResourceGroup '<Resource Group of the Virtual Network for the session hosts>' `
    -VmPassword '<Local administrator password for the session hosts>' `
    -VmSize '<SKU for the session hosts>' `
    -VmUsername '<Local administrator username for the session hosts>' `
    -Verbose
````

### Try with CLI

````cli
az deployment group create \
    --resource-group '<Resource Group Name>' \
    --template-uri 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/wvd/solution.json' \
    --parameters \
        AppGroupName '<WVD Application Group Name>' \
        AppGroupType '<WVD Application Group Type>' \
        Classification '<Solution Classification>' \
        CriticalityLevel '<Solution Criticality Level>' \
        CustomRdpProperty '<Custom RDP Properties for Host Pool>' \
        Department '<Company, Organization, or Agency Department>' \
        DiskSku '<VM Disk SKU>' \
        DomainAbbreviation '<Domain Name Abbreviation for Storage Account Name>' \
        DomainName '<Domain Name>' \
        DomainAdminPassword '<Privileged account password to domain join virtual machines>' \
        DomainAdminUsername '<Privileged account username to domain join virtual machines>'  \
        Environment '<Solution lifecycle environment>' \
        FileShareQuota '<File share quota for the FSLogix profiles>' \
        HostPoolType '<Host Pool Type>' \
        Identifier '<A value to identify the purpose of the deployment>' \
        ImageOffer '<Offer for image resource>' \
        ImagePublisher '<Publisher for image resource>' \
        ImageSku '<SKU for image resource>' \
        ImageVersion '<Version for image resource>' \
        Location '<Deployment location for all resources>' \
        MaxSessionLimit '<Host Pool Max Session Limit>' \
        newOrExisting '<Deploy the full solution or add new session hosts>' \
        Ordinal '<Integer to differentiate solution deployments per region>' \
        OuPath '<Distinguished name of the target OU>' \
        Owner '<Solution Owner>' \
        PreferredAppGroupType '<Preferred WVD application group type>' \
        Project '<Project Name for the WVD solution>' \
        Region '<Company, Organization, or Agency regional location>' \
        SecurityPrincipalId '<Azure AD Object ID for the security principal>' \
        SessionHostCount '<Number of session hosts to deploy>' \
        SessionHostIndex '<Number to start with for the session host name>' \
        StorageAccountSku '<SKU for the Azure Storage Account>' \
        Subnet '<Virtual Network Subnet for the sessions hosts>' \
        Timestamp '<unique value to redeploying the DSC and Domain Join extensions>' \
        ValidationEnvironment '<Host Pool Validation Environment>' \
        VirtualNetwork '<Virtual Network for the session hosts>' \
        VirtualNetworkResourceGroup '<Resource Group of the Virtual Network for the session hosts>' \
        VmPassword '<Local administrator password for the session hosts>' \
        VmSize '<SKU for the session hosts>' \
        VmUsername '<Local administrator username for the session hosts>'
````
