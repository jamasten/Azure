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
Imports an Image Version from an Azure Compute Gallery.
.DESCRIPTION
Imports a downloaded VHD as a Managed Disk and is validated using an MD5 hash that is auto-generated.  If the specified Compute Gallery and Image Definition do not exist, it creates those resources.  Next, the Managed Disk is imported as an Image Version.  Once the import completes, the Managed Disk is deleted.
.PARAMETER ComputeGalleryName
The name for the Azure Compute Gallery.  It will be created if it does not exist.
.PARAMETER ComputeGalleryResourceGroupName
The name for the Resource Group that contains the Azure Compute Gallery.
.PARAMETER ImageDefinitionAcceleratedNetworking
The accelerated networking feature for the Image Definition.
.PARAMETER ImageDefinitionHibernation
The hibernation feature for the Image Definition
.PARAMETER ImageDefinitionHyperVGeneration
The Hyper-V Generation for the Image Definition.
.PARAMETER ImageDefinitionName
The name for the Image Definition in the Azure Compute Gallery.  It will be created if it does not exist.
.PARAMETER ImageDefinitionOffer
The image offer for the Image Defintion.
.PARAMETER ImageDefinitionOsType
The operating system type for the Image Definition.
.PARAMETER ImageDefinitionPublisher
The publisher for the Image Defintion.
.PARAMETER ImageDefinitionSecurityType
The security type for the Image Definition. Note: What Azure calls "Standard" is defined as "None" when using the Powershell Module.
.PARAMETER ImageDefinitionSku
The SKU for the Image Defintion.
.PARAMETER ImageDefinitionState
The state for the Image Defintion.
.PARAMETER ImageVersionName
The name for the Image Version.
.NOTES
  Version:              1.3
  Author:               Jason Masten
  Contributors:         Philip Mallegol-Hansen
  Creation Date:        2022-05-11
  Last Modified Date:   2023-03-28
.EXAMPLE
.\Import-AzureComputeGalleryImageVersion.ps1 `
    -ComputeGalleryName 'cg_shared_d_eu' `
    -ComputeGalleryResourceGroupName 'rg-images-d-eu' `
    -ImageDefinitionAcceleratedNetworking 'False' `
    -ImageDefinitionHibernation 'False' `
    -ImageDefinitionHyperVGeneration 'V2' `
    -ImageDefinitionName 'WindowsServer2019Datacenter' `
    -ImageDefinitionOffer 'WindowsServer' `
    -ImageDefinitionOsType 'Windows' `
    -ImageDefinitionPublisher 'MicrosoftWindowsServer' `
    -ImageDefinitionSecurityType 'None' `
    -ImageDefinitionSku '2019-datacenter' `
    -ImageDefinitionState 'generalized' `
    -ImageVersionName '1.0.0'

This example imports the VHD as a Managed Disk, creates a new Image Defintion, and imports the Managed Disk as a new Image Version into the new Image Defintion.
.EXAMPLE
.\Import-AzureComputeGalleryImageVersion.ps1 `
    -ComputeGalleryName 'cg_shared_d_eu' `
    -ComputeGalleryResourceGroupName 'rg-images-d-eu' `
    -ImageDefinitionName 'WindowsServer2019Datacenter' `
    -ImageDefinitionOffer 'WindowsServer' `
    -ImageVersionName '1.0.0'

This example imports the VHD as a Managed Disk and imports the Managed Disk as a new Image Version into an existing Image Defintion.
#>
[Cmdletbinding()]
param(
    [parameter(Mandatory)]
    [string]$ComputeGalleryName,

    [parameter(Mandatory)]
    [string]$ComputeGalleryResourceGroupName,

    [parameter(Mandatory=$false)]
    [ValidateSet('True','False')]
    [string]$ImageDefinitionAcceleratedNetworking = 'False',

    [parameter(Mandatory=$false)]
    [ValidateSet('True','False')]
    [string]$ImageDefinitionHibernation = 'False',

    [parameter(Mandatory=$false)]
    [ValidateSet('V1','V2')]
    [string]$ImageDefinitionHyperVGeneration = 'V2',

    [parameter(Mandatory)]
    [string]$ImageDefinitionName,

    [parameter(Mandatory)]
    [string]$ImageDefinitionOffer,

    [parameter(Mandatory=$false)]
    [ValidateSet('Windows','Linux')]
    [string]$ImageDefinitionOsType = 'Windows',

    [parameter(Mandatory=$false)]
    [string]$ImageDefinitionPublisher,

    [parameter(Mandatory=$false)]
    [ValidateSet('ConfidentialVM','ConfidentialVMSupported','None','TrustedLaunch')]
    [string]$ImageDefinitionSecurityType = 'None',

    [parameter(Mandatory=$false)]
    [string]$ImageDefinitionSku,

    [parameter(Mandatory=$false)]
    [ValidateSet('generalized','specialized')]
    [string]$ImageDefinitionState,

    [parameter(Mandatory)]
    [string]$ImageVersionName
)

$ErrorActionPreference = 'Stop'

$DiskPrefix = "disk-$($ImageDefinitionName)-$($ImageVersionName)-"
$Location = (Get-AzResourceGroup -Name $ComputeGalleryResourceGroupName).Location

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
    -Name $ImageDefinitionName `
    -ErrorAction 'SilentlyContinue'

# If the Image Definition doesn't exist, create it
if(!$ImageDefinition)
{
    $IsHibernateSupported = @{Name = 'IsHibernateSupported'; Value = $ImageDefinitionHibernation}
    $IsAcceleratedNetworkSupported = @{Name = 'IsAcceleratedNetworkSupported'; Value = $ImageDefinitionAcceleratedNetworking}
    $SecurityType = @{Name = 'SecurityType'; Value = $ImageDefinitionSecurityType}
    $Features = @($IsHibernateSupported, $IsAcceleratedNetworkSupported, $SecurityType)

    $ImageDefinition = New-AzGalleryImageDefinition `
        -GalleryName $ComputeGalleryName `
        -ResourceGroupName $ComputeGalleryResourceGroupName `
        -Feature $Features `
        -HyperVGeneration $ImageDefinitionHyperVGeneration `
        -OsType $ImageDefinitionOsType `
        -Location $Location `
        -Name $ImageDefinitionName `
        -Offer $ImageDefinitionOffer `
        -OsState $ImageDefinitionState `
        -Publisher $ImageDefinitionPublisher `
        -Sku $ImageDefinitionSku
}

# Get the downloaded disks / VHDs from the Downloads folder
$Vhds = Get-ChildItem -Path "$($HOME)\Downloads\$($DiskPrefix)*.vhd"

# Throw an error if the disks are not found
if($Vhds.Count -eq 0)
{
    Write-Host -Message "Disks were not found. Be sure to use the same Image Definition Name used in the export script." -ForegroundColor Red
    throw
}

$DataDiskImage = @()
for($i = 0; $i -lt $Vhds.Count; $i++)
{
    # Uploads the VHD from the filesystem to Azure as a Managed Disk
    Add-AzVhd `
        -LocalFilePath "$($Vhds[$i].FullName)" `
        -ResourceGroupName $ComputeGalleryResourceGroupName `
        -Location $Location `
        -DiskName ($DiskPrefix + $i.ToString()) `
        -DiskOsType $ImageDefinitionOsType `
        -NumberOfUploaderThreads 32

    # Gets the information for the Managed Disk
    $Disk = Get-AzDisk `
        -ResourceGroupName $ComputeGalleryResourceGroupName `
        -DiskName ($DiskPrefix + $i.ToString())

    if($i -eq 0)
    {
        # Defines the Source object used to create the OS disk for the Image Version
        $OsDiskImage = @{Source = @{Id = $Disk.Id}}
    }
    else 
    {
        # Defines the Source object used to create a data disk for the Image Version
        $DataDisk = @{Source = @{Id = $Disk.Id}; Lun = ($i - 1)}
        $DataDiskImage += $DataDisk
    }
}

# Create a new Image Version using the Managed Disk(s)
if($Vhds.Count -eq 1)
{
    New-AzGalleryImageVersion `
        -GalleryImageDefinitionName $ImageDefinitionName `
        -GalleryImageVersionName $ImageVersionName `
        -GalleryName $ComputeGalleryName `
        -ResourceGroupName $ComputeGalleryResourceGroupName `
        -Location $Location `
        -OSDiskImage $OsDiskImage
}
else
{
    New-AzGalleryImageVersion `
        -GalleryImageDefinitionName $ImageDefinitionName `
        -GalleryImageVersionName $ImageVersionName `
        -GalleryName $ComputeGalleryName `
        -ResourceGroupName $ComputeGalleryResourceGroupName `
        -Location $Location `
        -OSDiskImage $OsDiskImage `
        -DataDiskImage $DataDiskImage
}

# Deletes the Managed Disk(s)
for($i = 0; $i -lt $Vhds.Count; $i++)
{
    Remove-AzDisk `
        -ResourceGroupName $ComputeGalleryResourceGroupName `
        -DiskName ($DiskPrefix + $i.ToString()) `
        -Force
}
