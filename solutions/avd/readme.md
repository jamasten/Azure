# Azure Virtual Desktop solution

## Deployment Options

### Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2Favd%2Fsolution.json)
[![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2Favd%2Fsolution.json)

### PowerShell

````powershell
New-AzDeployment `
    -Location '<Azure location>' `
    -TemplateFile 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/avd/solution.json' `
    -Verbose
````

### Azure CLI

````cli
az deployment sub create \
    --location '<Azure location>' \
    --template-uri 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/avd/solution.json'
````

## Description

This solution will deploy Azure Virtual Desktop in an Azure subscription.  Depending on the options selected, either a personal or pooled host pool can be deployed with this solution.  The pooled option will deploy an App Group with a role assignment and the required resources to enable FSLogix.

This solution automates many of the features that are usually enabled manually after deploying an AVD host pool.  Those features are:

- FSLogix: deploys the required resources to enable the feature:
  - Azure Storage Account or Azure NetApp Files with a fully configured file share
  - Management Virtual Machine with Custom Script Extension to:
    - Domain joins the Storage Account or creates the AD connection on the Azure NetApp Account
    - Sets the required permissions for access to the file share
  - Custom Script Extension on Session Hosts to enable FSLogix using registry settings
- Scaling Automation (pooled host pools only): deploys the required resources to enable the feature:
  - Automation Account with a Managed Identity
    - Runbook
    - Variable
    - PowerShell Modules
  - Logic App
  - Contributor role assignment on the AVD resource groups, limiting the privileges the Automation Account has in your subscription
- Start VM On Connect (Optional): deploys the required resources to enable the feature:
  - Role with appropriate permissions
  - Role assignment
  - Enables the feature on the AVD host pool
- VDI Optimization Script: removes unnecessary apps, services, and processes from your Windows 10 OS, improving performance and resource utilization.
- Monitoring: deploys the required resources to enable the Insights workbook:
  - Log Analytics Workspace with the required Windows Events and Performance Counters.
  - Microsoft Monitoring Agent on the session hosts.
  - Diagnostic settings on the AVD host pool and workspace.
- Graphics Drivers & Settings: deploys the extension to install the graphics driver and creates the recommended registry settings when an appropriate VM size (Nv, Nvv3, Nvv4, or NCasT4_v3 series) is selected.
- BitLocker Encryption (Optional): deploys the required resources & configuration to enable BitLocker encryption on the session hosts:
  - Key Vault with a Key Encryption Key
  - VM Extension to enable the feature on the virtual machines.
- Backups (Optional): deploys the required resources to enable backups:
  - Recovery Services Vault
  - Backup Policy
  - Protection Container (File Share Only)
  - Protected Item
- Screen Capture Protection (Optional): deploys the required registry setting on the AVD session hosts to enable the feature.
- Drain Mode (Optional): when enabled, the sessions hosts will be deployed in drain mode to ensure end users cannot access the host pool until operations is ready to allow connections.
- RDP ShortPath (Optional): deploys the requirements to enable RDP ShortPath for AVD.
- SMB Multichannel: Enables multiple connections to an SMB share.  This feature is only supported with a premium Azure Storage Account.

## Assumptions

To successfully deploy this solution, you will need to ensure your scenario matches the assumptions below:

- AVD supported marketplace image.
- Acquired the appropriate licensing for the operating system.
- Landing zone deployed in Azure:
  - Virtual network and subnet(s)
  - Deployed and configured domain services if domain joining the session hosts
- Correct RBAC assignment: this solution contains many role assignments so you will need to be a Subscription Owner for a successful deployment of all the features.

## Prerequisites

To successfully deploy this solution, you will need to first ensure the following prerequisites have been completed:

- Create a security group for your AVD users and if applicable, ensure the principal has synchronized with your domain services.
- If you plan to use Azure NetApp Files for FSLogix, complete the following:
  - [Register the resource provider](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-register)
  - [Delegate a subnet to Azure NetApp Files](https://docs.microsoft.com/en-us/azure/azure-netapp-files/azure-netapp-files-delegate-subnet)
  - [Enable the shared AD feature](https://docs.microsoft.com/en-us/azure/azure-netapp-files/create-active-directory-connections#shared_ad) if you plan to deploy more than one NetApp account in the same Azure subscription and region

## Considerations

If you need to redeploy this solution b/c of an error or other reason, be sure the virtual machines are turned on.  If your host pool is "pooled", I would recommended disabling your logic app to ensure the scaling solution doesn't turn off any of your VM's during the deployment.  If the VM's are off, the deployment will fail since the extensions cannot be validated / updated.

Azure NetApp Files can only have one Active Directory Connection per subscription per region.  Due to this design, when deploying ANF be sure to deploy the first ANF account by itself to establish the AD Connection.  Once that is established and the connection sharing feature is enabled, any number of ANF accounts may also be deployed to the same subscription and region.

## Post Deployment Requirements

When deploying FSLogix, a management VM is deployed to facilitate the domain join of the Azure Storage Account, if applicable, and sets the NTFS permissions on the chosen storage solution.  After the deployment succeeds, this VM and its associated resources may be removed.
