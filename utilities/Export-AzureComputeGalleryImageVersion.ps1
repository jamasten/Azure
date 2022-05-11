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

$ImageVersion = Get-AzGalleryImageVersion `
    -GalleryImageDefinitionName $ComputeGalleryDefinitionName `
    -GalleryName $ComputeGalleryName `
    -ResourceGroupName $ComputeGalleryResourceGroupName `
    -Name $ComputeGalleryVersion

$DiskConfig = New-AzDiskConfig `
    -Location $Location `
    -CreateOption FromImage `
    -GalleryImageReference @{Id = $ImageVersion.Id}

$Disk = New-AzDisk `
    -Disk $DiskConfig `
    -ResourceGroupName $ComputeGalleryResourceGroupName `
    -DiskName $DiskName

$DiskAccess = Grant-AzDiskAccess `
    -ResourceGroupName $Disk.ResourceGroupName `
    -DiskName $Disk.Name `
    -Access 'Read' `
    -DurationInSecond 14400

Get-AzStorageBlobContent `
    -AbsoluteUri $DiskAccess.AccessSAS `
    -Destination "$($HOME)\Downloads\$($Disk.Name).vhd"
    
Revoke-AzDiskAccess `
    -ResourceGroupName $Disk.ResourceGroupName `
    -DiskName $Disk.Name

Remove-AzDisk `
    -ResourceGroupName $Disk.ResourceGroupName `
    -DiskName $Disk.Name `
    -Force