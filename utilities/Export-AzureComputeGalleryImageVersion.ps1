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
Exports a VHD of a Managed Disk created from an Image Version in an Azure Compute Gallery.  The VHD is saved to the Downloads folder in the user's profile that is running the script.
.PARAMETER ComputeGalleryDefinitionName
The name of the Image Definition in the Azure Compute Gallery.
.PARAMETER ComputeGalleryName
The name of the Azure Compute Gallery.
.PARAMETER ComputeGalleryResourceGroupName
The name of the Resource Group that contains the Azure Compute Gallery.
.PARAMETER ComputeGalleryVersion
The name of the Image Version in the Azure Compute Gallery.
.NOTES
  Version:        1.0
  Author:         Jason Masten
  Creation Date:  2022-05-11
.EXAMPLE
.\Export-AzureComputeGalleryImageVersion.ps1 `
    -ComputeGalleryDefinitionName 'WindowsServer2019Datacenter' `
    -ComputeGalleryName 'cg_shared_d_va' `
    -ComputeGalleryResourceGroupName 'rg-images-d-va' `
    -ComputeGalleryVersion '1.0.0'

This example creates a Managed Disk from an Image Version in an Azure Compute Gallery. Downloads the VHD of the Managed Disk to the user's Downloads folder and validates the auto-generated MD5 hash.  Once the download completes, the Managed Disk is deleted. 
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
    [string]$ComputeGalleryVersion

)

$ErrorActionPreference = 'Stop'

$DiskName = "disk-$($ComputeGalleryDefinitionName)"
$Location = (Get-AzResourceGroup -Name $ComputeGalleryResourceGroupName).Location

# Gets the Image Gallery information
$ImageVersion = Get-AzGalleryImageVersion `
    -GalleryImageDefinitionName $ComputeGalleryDefinitionName `
    -GalleryName $ComputeGalleryName `
    -ResourceGroupName $ComputeGalleryResourceGroupName `
    -Name $ComputeGalleryVersion

# Creates a Disk Configuration for a Managed Disk using the Image Version in the Compute Gallery
$DiskConfig = New-AzDiskConfig `
    -Location $Location `
    -CreateOption FromImage `
    -GalleryImageReference @{Id = $ImageVersion.Id}

# Creates a Managed Disk using the Image Version in the Compute Gallery
$Disk = New-AzDisk `
    -Disk $DiskConfig `
    -ResourceGroupName $ComputeGalleryResourceGroupName `
    -DiskName $DiskName

# Creates a URI with a SAS Token to download the VHD of the Managed Disk
$DiskAccess = Grant-AzDiskAccess `
    -ResourceGroupName $Disk.ResourceGroupName `
    -DiskName $Disk.Name `
    -Access 'Read' `
    -DurationInSecond 14400

# Downloads the VHD using 10 concurrent network calls and validates the MD5 hash
Get-AzStorageBlobContent `
    -AbsoluteUri $DiskAccess.AccessSAS `
    -CheckMd5 `
    -Destination "$($HOME)\Downloads\$($Disk.Name).vhd"

# Revokes the SAS Token to download the VHD
Revoke-AzDiskAccess `
    -ResourceGroupName $Disk.ResourceGroupName `
    -DiskName $Disk.Name

# Deletes the Managed Disk
Remove-AzDisk `
    -ResourceGroupName $Disk.ResourceGroupName `
    -DiskName $Disk.Name `
    -Force