param(
    
    [parameter(Mandatory)]
    [string]$Availability,

    [parameter(Mandatory)]
    [string]$DiskSku,

    [parameter(Mandatory)]
    [string]$ImageSku,

    [parameter(Mandatory)]
    [string]$Location,

    [parameter(Mandatory)]
    [int]$SessionHostCount,

    [parameter(Mandatory)]
    [int]$SessionHostIndex,

    [parameter(Mandatory)]
    [string]$VmSize
)


############################################################################################
# Session Host Batching
############################################################################################
# sessionHosts.bicep file can only support 99 virtual machines in each nested deployment
# 3 static resources
# 8 looped resources
# (8 * 99) + 3 = 795 resources; limit is 800 resources per deployment
# BATCH determines how many virtual machines will be deployed in each deployment
# INDEX determines the number of the first virtual machine in each batch that will be deployed
if($Count -gt 99)
{
    $DivisionValue = [math]::Truncate($Count / 99)
    $RemainderValue = $Count % 99
    $Batches = @()
    $Indexes = @()
    for($i = 0; $i -lt $DivisionValue; $i++)
    {
        # Add first batch manually
        $Batches += 99
        
        if($i -eq 0)
        {
            # Add first index manually
            $Indexes += $Index
        }
        else
        {
            if($Index -eq 0)
            {
                # Create indexes by subtracting 1 if index starts at 0; corrects offset
                $Indexes += ((99 * $i) + $Index) - 1
            }
            else
            {
                # Create indexes when Index is greater than 0; no offset required
                $Indexes += (99 * $i) + $Index
            }
        }
    }
    if($RemainderValue -gt 0)
    {
        # Add last batch if there is a remainder in the division
        $Batches += $RemainderValue
        if($Index -eq 0)
        {   
            # Create remainder index by subtracting 1 if the index starts at 0; corrects offset
            $Indexes += ((99 * $DivisionValue) + $Index) - 1
        }
        else
        {
            # Create remainder index when Index is greater than 0; no offset required
            $Indexes += (99 * $DivisionValue) + $Index
        }
    }
}
else 
{
    $Batches = @($Count)
    $Indexes = @($Index)
}


############################################################################################
# Availability Zone Validation
############################################################################################
$Sku = Get-AzComputeResourceSku -Location $Location | Where-Object {$_.ResourceType -eq 'virtualMachines' -and $_.Name -eq $VmSize}
if($Availability -eq 'AvailabilityZones' -and $Sku.locationInfo.zones.count -lt 3)
{
    Write-Error -Exception 'Invalid Availability' -Message 'The selected VM Size does not support availability zones in this Azure location. https://docs.microsoft.com/en-us/azure/virtual-machines/windows/create-powershell-availability-zone' -ErrorAction Stop
} 
elseif($Availability -eq 'AvailabilityZones' -and $Sku.locationInfo.zones.count -eq 3)
{
    $Zones = $true
} 
else 
{
    $Zones = $false
}


############################################################################################
# vCPU Count Validation
############################################################################################
# Recommended range is 4 min, 24 max
# https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/virtual-machine-recs?context=/azure/virtual-desktop/context/context
$vCPUs = [int]($Sku.capabilities | Where-Object {$_.name -eq 'vCPUs'}).value
if($vCPUs -lt 4 -or $vCPUs -gt 24)
{
    Write-Error -Exception 'Invalid vCPU Count' -Message 'The selected VM Size does not contain the appropriate amount of vCPUs for Azure Virtual Desktop. https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/virtual-machine-recs' -ErrorAction Stop
}


############################################################################################
# Disk SKU validation
############################################################################################
if($DiskSku -like "Premium*" -and ($Sku.capabilities | Where-Object {$_.name -eq 'PremiumIO'}).value -eq $false)
{
    Write-Error -Exception 'Invalid Disk SKU' -Message 'The selected VM Size does not support the Premium SKU for managed disks.' -ErrorAction Stop
}


############################################################################################
# Hyper-V Generation validation
############################################################################################
if($ImageSku -like "*-g2" -and ($Sku.capabilities | Where-Object {$_.name -eq 'HyperVGenerations'}).value -notlike "*2")
{
    Write-Error -Exception 'Invalid Hyper-V Generation' -Message 'The VM size does not support the selected Image Sku.' -ErrorAction Stop
}


############################################################################################
# Output
############################################################################################
$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs["acceleratedNetworking"] = ($Sku.capabilities | Where-Object {$_.name -eq 'AcceleratedNetworkingEnabled'}).value
$DeploymentScriptOutputs["sessionHostBatches"] = $Batches
$DeploymentScriptOutputs["sessionHostIndexes"] = $Indexes