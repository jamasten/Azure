# Azure Virtual Desktop - Remove Expired FSLogix Profiles

## Description

This solution will deploy a virtual machine weekly and run the [Invoke-FslShrinkDisk](https://github.com/FSLogix/Invoke-FslShrinkDisk/blob/master/Invoke-FslShrinkDisk.ps1) tool against your SMB shares to remove VHDs older than the specified amount of days.  Once the tool has completed, the virtual machine is deleted to save on compute and storage charges. The following resources are deployed in this solution:

* Automation Account
  * Job Schedule
  * Runbook
  * Schedule
* Key Vault
  * Secrets
* Role Assignments
* Template Spec
* User Assigned Identity

## Deployment Options

### Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmain%2Fsolutions%2FfslogixDiskShrinkAutomation%2Fsolution.json)
[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmain%2Fsolutions%2FfslogixDiskShrinkAutomation%2Fsolution.json)

### PowerShell

````powershell
New-AzResourceGroupDeployment `
    -ResourceGroupName '<Resource Group Name>' `
    -TemplateFile 'https://raw.githubusercontent.com/jamasten/Azure/main/solutions/fslogixDiskShrinkAutomation/solution.json' `
    -Verbose
````

### Azure CLI

````cli
az deployment group create \
    --resource-group '<Resource Group Name>' \
    --template-uri 'https://raw.githubusercontent.com/jamasten/Azure/main/solutions/fslogixDiskShrinkAutomation/solution.json'
````
