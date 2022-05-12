# REFERENCE: https://docs.microsoft.com/en-us/azure/virtual-machines/managed-disk-from-image-version

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