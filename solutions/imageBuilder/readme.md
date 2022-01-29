# Azure Image Builder

## Deployment Options

### Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https%3A%2F%2Fgithub.com%2Fjamasten%2FAzure%2Fblob%2Fmaster%2Fsolutions%2FimageBuilder%2Fsolution.json)
[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https%3A%2F%2Fgithub.com%2Fjamasten%2FAzure%2Fblob%2Fmaster%2Fsolutions%2FimageBuilder%2Fsolution.json)

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

## Description

This solution will deploy all the resources needed to build an image with Azure Image Builder.  The Image Template is currently configured to add Microsoft Teams, reboot, and update the operating system.  The deployment will store the image in a Shared Image Gallery.

## Prerequisites

Refer to the official Azure Image Builder Docs page for current prerequisites: [https://docs.microsoft.com/en-us/azure/virtual-machines/image-builder-overview](https://docs.microsoft.com/en-us/azure/virtual-machines/image-builder-overview) 