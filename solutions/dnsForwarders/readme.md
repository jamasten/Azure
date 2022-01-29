# DNS Forwarders for Private Link solution

## Deployment Options

### Try with Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2FdnsForwarders%2Ftemplate.json)
[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2FdnsForwarders%2Ftemplate.json)

### Try with PowerShell

````powershell
New-AzResourceGroupDeployment `
    -ResourceGroupName '<Resource Group Name>' `
    -TemplateUri 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/dnsForwarders/template.json'
````

### Try with CLI

````cli
az deployment group create \
    --resource-group '<Resource Group Name>' \
    --template-uri 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/dnsForwarders/template.json' \
    --parameters \
        AvSetName '<Availability Set Name>'
````

## Assumptions

Your DNS servers are on premise and you need DNS servers in Azure to support Private Link.

## Description

This solution will deploy two Windows DNS servers in an Availability Set, configure a DNS Conditional Forwarder for Azure Storage, and configure a DNS Forwarder to your on premise DNS servers.
