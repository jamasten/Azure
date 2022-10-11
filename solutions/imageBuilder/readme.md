# Azure Image Builder

This solution will deploy all the Azure resources needed to build an image with Azure Image Builder (AIB). It includes all of Microsoft's security best practices. Each time a new build is run, the AIB service will use a pre-configured virtual network with private link to connect to the virtual machine. This avoids the use of public IP addresses. The role assignments given to the AIB service and Automation Account are the minimum required, adhering to least privilege.

The Image Template is currently configured to run the [Virtual Desktop Optimization Tool](https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool), install Microsoft Project & Visio, and update the operating system. The customization steps in the Image Template can be modified to fulfill your solution requirements. Refer to the [Microsoft Learn page](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/image-builder-json?tabs=json%2Cazure-powershell#properties-customize) for details on the allowed customizations.

A feature of this solution is build automation. This feature uses an Automation Runbook and a Logic App to check if a new Azure Marketplace image version has been released since you're last Image Template build. If the Marketplace image version is newer, a new build will be initiated on the Image Template.

The following resources are deployed with this solution:

- Automation Account
  - Diagnostic Setting
  - Modules
  - Runbook
  - Webhook
- Compute Gallery
  - Image Definition
- Deployment Script
- Image Template
- Logic App
- Role Definitions
- Role Assignments
- User Assigned Identity

## Prerequisites

- Ensure the target subnet has an assigned Network Security Group and has the required rule configured: [PowerShell for NSG Rule](https://learn.microsoft.com/en-us/azure/virtual-machines/windows/image-builder-vnet#add-an-nsg-rule)

## Deployment Options

### Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2FimageBuilder%2Fsolution.json)
[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2FimageBuilder%2Fsolution.json)

### PowerShell

````powershell
New-AzDeployment `
    -Location '<Azure location>' `
    -TemplateFile 'https://github.com/jamasten/Azure/blob/master/solutions/imageBuilder/solution.json' `
    -Verbose
````

### Azure CLI

````cli
az deployment sub create \
    --location '<Azure location>' \
    --template-uri 'https://github.com/jamasten/Azure/blob/master/solutions/imageBuilder/solution.json'
````
