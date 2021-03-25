# Scale WVD Session Hosts using Azure Automation

## STEP 1: Deploy the Automation Account

### Description

This ARM template will deploy the following resources:

* Automation Account
* Automation Account Modules
* Automation Account Runbook
* Automation Account Webhook
* Automation Account Variable
* Diagnostic Settings for the Automation Account (Optional)

### Template Parameters

#### REQUIRED

* **AutomationAccountName**: Name of an existing Automation Account or the desired name for a new Automation Account
* **Version**: Choose between ARM and Classic version of WVD

#### OPTIONAL

* **WorkspaceName**: Name of the Log Analytics Workspace to use for logging the Runbook jobs in Azure Automation
* **WorkspaceResourceGroupName**: Resource Group Name of the Log Analytics Workspace to use for logging the Runbook jobs in Azure Automation

### Try with Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzurePolicies%2Fmaster%2Fpolicies%2Fgovernance%2FnamingStandard%2FvirtualMachine%2Fpolicy.json)
[![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzurePolicies%2Fmaster%2Fpolicies%2Fgovernance%2FnamingStandard%2FvirtualMachine%2Fpolicy.json)

### Try with PowerShell

````powershell
New-AzResourceGroupDeployment `
    -ResourceGroupName '<Resource Group Name>' `
    -TemplateFile 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/wvd-templates/wvd-scaling-script/scripts/scalingAutomationAccount.json' `
    -AutomationAccountName '<Automation Account Name>' `
    -Version '<ARM or Classic>' `
    -WorkspaceName '<Log Analytics Workspace Name>' `
    -WorkspaceResourceGroupName '<Log Analytics Workspace Resource Group Name>' `
    -Verbose
````

### Try with CLI

````cli
az deployment group create \
    --resource-group <Resource Group Name> \
    --template-uri 'https://raw.githubusercontent.com/Azure/RDS-Templates/master/wvd-templates/wvd-scaling-script/scripts/scalingAutomationAccount.json' `
    --AutomationAccountName '<Automation Account Name>' `
    --Version '<ARM or Classic>' `
    --WorkspaceName '<Log Analytics Workspace Name>' `
    --WorkspaceResourceGroupName '<Log Analytics Workspace Resource Group Name>' `
    --Verbose
````
