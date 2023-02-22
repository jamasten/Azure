# Auto Increase Premium File Share Quota

This solution will deploy the required Azure resources to scale the quota of a file share on Azure Files Premium. File shares on Azure Files Premium are billed by the size of the quota, not the amount of consumed storage. So it is important to ensure the quota is managed and kept at the minimum size to reduce cost.

If there is more than one share on the Storage Account, each share can be specified to scale each. Only one Automation Account is required to support the scaling of multiple shares. However, each share will require its own dedicated Logic App.

## Resources

The following resources are deployed with this solution:

- Automation Account
  - Runbook
  - Webhook
  - Diagnostic Setting (Optional)
- Logic App
- Role Assignments
- Action Group (Optional)
- Alerts (Optional)

## Prerequisites

- To deploy this solution, the principal must have Owner privileges on the Azure subscription.
- To setup the monitoring capabilities with this solution, you must have an existing Log Analytics Workspace.

## Deployment Options

### Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmain%2Fsolutions%2FautoIncreasePremiumFileShareQuota%2Fsolution.json)
[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmain%2Fsolutions%2FautoIncreasePremiumFileShareQuota%2Fsolution.json)

### PowerShell

````powershell
New-AzDeployment `
    -Location '<Azure location>' `
    -TemplateFile 'https://raw.githubusercontent.com/jamasten/Azure/main/solutions/autoIncreasePremiumFileShareQuota/solution.json' `
    -Verbose
````

### Azure CLI

````cli
az deployment sub create \
    --location '<Azure location>' \
    --template-uri 'https://raw.githubusercontent.com/jamasten/Azure/main/solutions/autoIncreasePremiumFileShareQuota/solution.json'
````
