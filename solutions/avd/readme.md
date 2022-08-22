# Azure Virtual Desktop Solution

[**Home**](./readme.md) | [**Features**](./docs/features.md) | [**Design**](./docs/design.md) | [**Prerequisites**](./docs/prerequisites.md) | [**Post Deployment**](./docs/post.md) | [**Troubleshooting**](./docs/troubleshooting.md)

This Azure Virtual Desktop (AVD) solution will deploy a fully operational [stamp](https://docs.microsoft.com/en-us/azure/architecture/patterns/deployment-stamp) in an Azure subscription. Many of the [features](./docs/features.md) used with AVD have been automated in this solution for your convenience.  When deploying this solution be sure to read the descriptions for each parameter to the understand the consequences of your selection. To target the desired marketplace image for your session hosts, use the code below:

```powershell
# Determine the Publisher; input the location for your AVD deployment
$Location = ''
(Get-AzVMImagePublisher -Location $Location).PublisherName

# Determine the Offer; common publisher is 'MicrosoftWindowsDesktop' for Win 10/11
$Publisher = ''
(Get-AzVMImageOffer -Location $Location -PublisherName $Publisher).Offer

# Determine the SKU; common offers are 'Windows-10' for Win 10 and 'office-365' for the Win10/11 multi-session with M365 apps
$Offer = ''
(Get-AzVMImageSku -Location $Location -PublisherName $Publisher -Offer $Offer).Skus

# Determine the Image Version; common offers are '21h1-evd-o365pp' and 'win11-21h2-avd-m365'
$Sku = ''
Get-AzVMImage -Location $Location -PublisherName $Publisher -Offer $Offer -Skus $Sku | Select-Object * | Format-List

# Common version is 'latest'
```

## Deployment Options

> **WARNING**: Be sure to review the [prerequisites](./docs/prerequisites.md) before deploying this solution.

### Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2Favd%2Fsolution.json)
[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2Favd%2Fsolution.json)

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
