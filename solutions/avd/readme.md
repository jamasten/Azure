# Azure Virtual Desktop solution

This solution will deploy Azure Virtual Desktop in an Azure subscription.  Depending on the options selected, either a personal or pooled host pool can be deployed with this solution.  The pooled option will deploy an App Group with a role assignment and everything to enable FSLogix.

This solution contains many features that are usually enabled manually after deploying an AVD host pool.  Those features are:

- FSLogix (Pooled host pools only): deploys the required resources to enable the feature:
  - Azure Storage Account
  - Azure File Share
  - Management Virtual Machine with Custom Script Extension to:
    - Domain join the Storage Account
    - Sets the Share and NTFS permissions
  - Custom Script Extension on Session Hosts to enable FSLogix using registry settings
- Scaling Automation (Pooled host pools only): deploys the required resources to enable the feature:
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
- AVD Monitoring Solution: deploys the required resources to enable the Insights workbook:
  - Log Analytics Workspace with the required Windows Events and Performance Counters.
  - Microsoft Monitoring Agent on the session hosts.
  - Diagnostic settings on the AVD host pool and workspace.
- Graphics Drivers: deploys the required extension to install the graphics driver when the appropriate VM sizes are selected.
- Backups (Optional): deploys the required resources to enable backups:
  - Recovery Services Vault
  - Backup Policy
  - Protection Container (File Share Only)
  - Protected Item

## Assumptions

To successfully deploy this solution, you will need to ensure your scenario matches the assumptions below:

- AVD supported marketplace image.
- Acquired the appropriate licensing for the operating system.
- Landing zone deployed in Azure:
  - Virtual network and subnet(s)
  - ADDS synchronized with Azure AD
- Correct RBAC assignment: this solution contains many role assignments so you will need to be a Subscription Owner for a successful deployment of all the features.

## Prerequisites

To successfully deploy this solution, you will need to first ensure the following prerequisites have been completed:

- Create a Security Group in ADDS for your AVD users.  Once the object has synchronized to Azure AD, make note of the name and object ID in Azure AD.  This will be needed to deploy the solution.

## Considerations

If you are deploying this solution to multiple subscriptions in the same tenant and want to use the Start VM On Connect feature, set the StartVmOnConnect parameter to false.  The custom role should be created at the Management Group scope.  The role assignment for the WVD service using the custom role should be set at the Management Group scope as well.  The Start VM On Connect feature would need to be manually enabled on the host pool per deployment.

## Post Deployment Requirements

- When deploying a "pooled" host pool, a management VM is deployed to facilitate the domain join of the Azure Storage Account and to set the NTFS permissions on the Azure File Share.  After the deployment succeeds, this VM and its associated resources may be removed.

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
