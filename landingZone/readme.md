# Azure Landing Zone

## Prerequisites

Azure AD DS Only: there are prerequisites to deploy Azure AD DS in an Azure subscription and are contained in the "preDeployment.ps1" script file.

## Deployment Options

### Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2FlandingZone%2Fsolution.json)
[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2FlandingZone%2Fsolution.json)

### PowerShell

````powershell
New-AzDeployment `
    -Location '<Azure location>' `
    -TemplateFile 'https://raw.githubusercontent.com/jamasten/Azure/master/landingZone/solution.json' `
    -Verbose
````

### Azure CLI

````cli
az deployment sub create \
    --location '<Azure location>' \
    --template-uri 'https://raw.githubusercontent.com/jamasten/Azure/master/landingZone/solution.json'
````

## Description

A landing zone is the core infrastructure needed to support a workload in Azure.  Typically this involves your networking and identity.

This solution allows you to choose from 3 identity options:

1. Active Directory Domain Services on Azure IaaS virtual machines
1. Azure Active Directory Domain Services with a managed domain
1. Azure Active Directory

The solution will also deploy the following Azure resources:

+ Virtual Network with subnets
+ Network Security Groups
+ Network Watcher
+ Bastion
+ Key Vault with Secrets
+ Log Analytics Workspace

## Post Deployment

AD DS Only: while most of the infrastructure is deployed using the templates and scripts, Azure AD Connect cannot be automated.  Since this solution is meant for a lab or development, Azure AD Connect can be installed on the IaaS domain controller.  The directions can be found [here](https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-install-express).
