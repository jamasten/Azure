<#
MIT License

Copyright (c) 2022 Jason Masten

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

.SYNOPSIS
Exports an Image Version from an Azure Compute Gallery.
.DESCRIPTION
Exports an Image Version from an Azure Compute Gallery.
.PARAMETER ComputeGalleryDefinitionName
The name of the Image Definition in the Azure Compute Gallery.
.PARAMETER ComputeGalleryName
The name of the Azure Compute Gallery.
.PARAMETER ComputeGalleryResourceGroupName
The name of the Resource Group that contains the Azure Compute Gallery.
.PARAMETER ComputeGalleryVersion
The name of the Image Version in the Azure Compute Gallery.
.PARAMETER ImageOffer
The offer of the image to create a new Image Defintion if needed.
.PARAMETER ImagePublisher
The publisher of the image to create a new Image Defintion if needed.
.PARAMETER ImageSku
The SKU of the image to create a new Image Defintion if needed.
.PARAMETER ImageState
The state of the image to create a new Image Defintion if needed.
.PARAMETER VhdFilePath
The file path to the VHD on the filesystem.
.NOTES
  Version:        1.0
  Author:         Jason Masten
  Creation Date:  2022-05-11
.EXAMPLE
.\Import-AzureComputeGalleryImageVersion.ps1 `
    -ComputeGalleryDefinitionName 'WindowsServer2019Datacenter' `
    -ComputeGalleryName 'cg_shared_d_eu' `
    -ComputeGalleryResourceGroupName 'rg-images-d-eu' `
    -ComputeGalleryVersion '1.0.0' `
    -ImageOffer 'WindowsServer' `
    -ImagePublisher 'MicrosoftWindowsServer' `
    -ImageSku '2019-datacenter' `
    -ImageState 'generalized' `
    -VhdFilePath $HOME\Downloads\disk-WindowsServer2019Datacenter.vhd

This example imports the VHD as a Managed Disk, creates a new Image Defintion, and imports the Managed Disk as a new Image Version into the new Image Defintion.
.EXAMPLE
.\Import-AzureComputeGalleryImageVersion.ps1 `
    -ComputeGalleryDefinitionName 'WindowsServer2019Datacenter' `
    -ComputeGalleryName 'cg_shared_d_eu' `
    -ComputeGalleryResourceGroupName 'rg-images-d-eu' `
    -ComputeGalleryVersion '1.0.0' `
    -VhdFilePath $HOME\Downloads\disk-WindowsServer2019Datacenter.vhd

This example imports the VHD as a Managed Disk and imports the Managed Disk as a new Image Version into an existing Image Defintion.
#>
[Cmdletbinding()]
param(

    [parameter(Mandatory)]
    [string]$ComputeGalleryDefinitionName,

    [parameter(Mandatory)]
    [string]$ComputeGalleryName,

    [parameter(Mandatory)]
    [string]$ComputeGalleryResourceGroupName,

    [parameter(Mandatory)]
    [string]$ComputeGalleryVersion,

    [parameter(Mandatory=$false)]
    [string]$ImageOffer,

    [parameter(Mandatory=$false)]
    [string]$ImagePublisher,

    [parameter(Mandatory=$false)]
    [string]$ImageSku,

    [parameter(Mandatory=$false)]
    [ValidateSet('generalized','specialized')]
    [string]$ImageState,

    [parameter(Mandatory)]
    [string]$VhdFilePath

)

$ErrorActionPreference = 'Stop'

$DiskName = "disk-$($ComputeGalleryDefinitionName)"
$Location = (Get-AzResourceGroup -Name $ComputeGalleryResourceGroupName).Location

# Uploads the VHD from the filesystem to Azure as a Managed Disk
Add-AzVhd `
    -LocalFilePath $VhdFilePath `
    -ResourceGroupName $ComputeGalleryResourceGroupName `
    -Location $Location `
    -DiskName $DiskName `
    -NumberOfUploaderThreads 32

# Gets the information for the Managed Disk
$Disk = Get-AzDisk `
    -ResourceGroupName $ComputeGalleryResourceGroupName `
    -DiskName $DiskName

# Checks if the Compute Gallery exists
$Gallery = Get-AzGallery `
    -ResourceGroupName $ComputeGalleryResourceGroupName `
    -Name $ComputeGalleryName `
    -ErrorAction 'SilentlyContinue'

# If the Compute Gallery doesn't exist, create it
if(!$Gallery)
{ 
    $Gallery = New-AzGallery `
        -ResourceGroupName $ComputeGalleryResourceGroupName `
        -Name $ComputeGalleryName `
        -Location $Location
}

# Checks if the Image Definition exists
$ImageDefinition = Get-AzGalleryImageDefinition `
    -GalleryName $ComputeGalleryName `
    -ResourceGroupName $ComputeGalleryResourceGroupName `
    -Name $ComputeGalleryDefinitionName `
    -ErrorAction 'SilentlyContinue'

# If the Image Definition doesn't exist, create it
if(!$ImageDefinition)
{ 
    $ImageDefinition = New-AzGalleryImageDefinition `
        -GalleryName $ComputeGalleryName `
        -ResourceGroupName $ComputeGalleryResourceGroupName `
        -Location $Location `
        -Name $ComputeGalleryDefinitionName `
        -OsState $ImageState `
        -OsType $Disk.OsType `
        -Publisher $ImagePublisher `
        -Offer $ImageOffer `
        -Sku $ImageSku
}

# Creates the Source object used to create the Image Version
$OsDiskImage = @{Source = @{Id = $Disk.Id }}

# Create a new Image Version using the Managed Disk
New-AzGalleryImageVersion `
    -GalleryImageDefinitionName $ComputeGalleryDefinitionName `
    -GalleryImageVersionName '1.0.0' `
    -GalleryName $ComputeGalleryName `
    -ResourceGroupName $ComputeGalleryResourceGroupName `
    -Location $Location `
    -OSDiskImage $OsDiskImage

# Deletes the Managed Disk
Remove-AzDisk `
    -ResourceGroupName $Disk.ResourceGroupName `
    -DiskName $Disk.Name `
    -Force