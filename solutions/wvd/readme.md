# Create or Update a WVD deployment

## Prerequisites

- Setup an OU in ADDS for your WVD Session Hosts. Make note of its Distinguished Name
- Create Security Groups in ADDS for your WVD users and administrators.  Once these objects have synchronized to Azure AD, make note of their Object ID's in Azure AD.

## Template Parameters

### REQUIRED

### OPTIONAL

### Try with Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2Fwvd%2Fsolution.json)
[![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2Fwvd%2Fsolution.json)

### Try with PowerShell

````powershell
New-AzResourceGroupDeployment `
    -ResourceGroupName '<Resource Group Name>' `
    -TemplateFile 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/wvd/solution.json' `
    -Verbose
````

### Try with CLI

````cli
az deployment group create \
    --resource-group '<Resource Group Name>' \
    --template-uri 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/wvd/solution.json' \
    --parameters \
        AppGroupDescription='<>' \
        AppGroupName='<>' \
        AppGroupType='<>'
````
