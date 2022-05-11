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

    [parameter(Mandatory)]
    [string]$ImageOffer,

    [parameter(Mandatory)]
    [string]$ImagePublisher,

    [parameter(Mandatory)]
    [string]$ImageSku,

    [parameter(Mandatory)]
    [ValidateSet('generalized','specialized')]
    [string]$ImageState,

    [parameter(Mandatory)]
    [string]$VhdFilePath

)

$ErrorActionPreference = 'Stop'

$DiskName = "disk-$($ComputeGalleryDefinitionName)"
$Location = (Get-AzResourceGroup -Name $ComputeGalleryResourceGroupName).Location

# Uploads VHD from filesystem to Azure as a Managed Disk
Add-AzVhd `
    -LocalFilePath $VhdFilePath `
    -ResourceGroupName $ComputeGalleryResourceGroupName `
    -Location $Location `
    -DiskName $DiskName `
    -NumberOfUploaderThreads 32

# Get Disk information
$Disk = Get-AzDisk `
    -ResourceGroupName $ComputeGalleryResourceGroupName `
    -DiskName $DiskName

# Check if Compute Gallery exists
$Gallery = Get-AzGallery `
    -ResourceGroupName $ComputeGalleryResourceGroupName `
    -Name $ComputeGalleryName `
    -ErrorAction 'SilentlyContinue'

# If Compute Gallery doesn't exist, create it
if(!$Gallery)
{ 
    $Gallery = New-AzGallery `
        -ResourceGroupName $ComputeGalleryResourceGroupName `
        -Name $ComputeGalleryName `
        -Location $Location
}

# Check if Image Definition exists
$ImageDefinition = Get-AzGalleryImageDefinition `
    -GalleryName $ComputeGalleryName `
    -ResourceGroupName $ComputeGalleryResourceGroupName `
    -Name $ComputeGalleryDefinitionName `
    -ErrorAction 'SilentlyContinue'

# If Image Definition doesn't exist, create it
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

# Get source disk
$OsDiskImage = @{Source = @{Id = $Disk.Id }}

# Create new gallery image version using the managed disk
New-AzGalleryImageVersion `
    -GalleryImageDefinitionName $ComputeGalleryDefinitionName `
    -GalleryImageVersionName '1.0.0' `
    -GalleryName $ComputeGalleryName `
    -ResourceGroupName $ComputeGalleryResourceGroupName `
    -Location $Location `
    -OSDiskImage $OsDiskImage

# Delete the managed disk
Remove-AzDisk `
    -ResourceGroupName $Disk.ResourceGroupName `
    -DiskName $Disk.Name `
    -Force