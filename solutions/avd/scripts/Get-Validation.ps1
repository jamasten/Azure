param(
    
    [parameter(Mandatory)]
    [string]$Availability,

    [parameter(Mandatory)]
    [string]$DiskSku,

    [parameter(Mandatory)]
    [string]$DomainName,

    [parameter(Mandatory)]
    [string]$DomainServices,

    [parameter(Mandatory)]
    [string]$FSLogixStorage,

    [parameter(Mandatory)]
    [string]$ImageSku,

    [parameter(Mandatory)]
    [string]$KerberosEncryption,

    [parameter(Mandatory)]
    [string]$Location,

    [parameter(Mandatory)]
    [array]$SecurityPrincipalIds,

    [parameter(Mandatory)]
    [array]$SecurityPrincipalNames,

    [parameter(Mandatory)]
    [int]$SessionHostCount,

    [parameter(Mandatory)]
    [int]$SessionHostIndex,
    
    [parameter(Mandatory)]
    [int]$StorageCount,    

    [parameter(Mandatory)]
    [string]$VmSize,

    [parameter(Mandatory)]
    [string]$VnetName,

    [parameter(Mandatory)]
    [string]$VnetResourceGroupName
)

$ErrorActionPreference = 'Stop'

# Object for collecting output
$DeploymentScriptOutputs = @{}

# Info required for validation
$Sku = Get-AzComputeResourceSku -Location $Location | Where-Object {$_.ResourceType -eq 'virtualMachines' -and $_.Name -eq $VmSize}


############################################################################################
# Storage Assignment Validation
############################################################################################
# Validate the array length for the Security Principal ID's, Security Principal Names, and Storage Count align
if($StorageCount -ne $SecurityPrincipalIds.Count -or $StorageCount -ne $SecurityPrincipalNames.Count)
{
    Write-Error -Exception 'Invalid Arrays' -Message 'The Security Prinicapl IDs count, Security Principal Names count, and Storage count must have the same value.'
}


############################################################################################
# Availability Zone Validation
############################################################################################
if($Availability -eq 'AvailabilityZones' -and $Sku.locationInfo.zones.count -lt 3)
{
    Write-Error -Exception 'Invalid Availability' -Message 'The selected VM Size does not support availability zones in this Azure location. https://docs.microsoft.com/en-us/azure/virtual-machines/windows/create-powershell-availability-zone'
} 


############################################################################################
# vCPU Count Validation
############################################################################################
# Recommended range is 4 min, 24 max
# https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/virtual-machine-recs?context=/azure/virtual-desktop/context/context
$vCPUs = [int]($Sku.capabilities | Where-Object {$_.name -eq 'vCPUs'}).value
if($vCPUs -lt 4 -or $vCPUs -gt 24)
{
    Write-Error -Exception 'Invalid vCPU Count' -Message 'The selected VM Size does not contain the appropriate amount of vCPUs for Azure Virtual Desktop. https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/virtual-machine-recs'
}


############################################################################################
# vCPU Quota Validation
############################################################################################
$Family = (Get-AzComputeResourceSku -Location $Location | Where-Object {$_.Name -eq $VmSize}).Family
$CpuData = Get-AzVMUsage -Location $Location | Where-Object {$_.Name.Value -eq $Family}
$AvailableCores = $CpuData.Limit - $CpuData.CurrentValue
$RequestedCores = $vCPUs * $SessionHostCount
if($RequestedCores -gt $AvailableCores)
{
    Write-Error -Exception 'Insufficient Core Quota' -Message 'The selected VM Family does not have adequate core quota in the selected location.  Request more quota and once that has been provided, you may redeploy.'
}


############################################################################################
# Disk SKU validation
############################################################################################
if($DiskSku -like "Premium*" -and ($Sku.capabilities | Where-Object {$_.name -eq 'PremiumIO'}).value -eq $false)
{
    Write-Error -Exception 'Invalid Disk SKU' -Message 'The selected VM Size does not support the Premium SKU for managed disks.'
}


############################################################################################
# Hyper-V Generation validation
############################################################################################
if($ImageSku -like "*-g2" -and ($Sku.capabilities | Where-Object {$_.name -eq 'HyperVGenerations'}).value -notlike "*2")
{
    Write-Error -Exception 'Invalid Hyper-V Generation' -Message 'The VM size does not support the selected Image Sku.'
}


############################################################################################
# Kerberos Encryption Type validation
############################################################################################
if($DomainServices -eq 'AzureActiveDirectory')
{
    $KerberosRc4Encryption = (Get-AzResource -Name $DomainName -ExpandProperties).Properties.domainSecuritySettings.kerberosRc4Encryption
    if($KerberosRc4Encryption -eq 'Enabled' -and $KerberosEncryption -eq 'AES256')
    {
        Write-Error -Exception 'Invalid Kerberos Encryption' -Message 'The Kerberos Encryption on Azure AD DS does not match your Kerberos Encyrption selection.  Please choose a different Kerberos Encryption Type or fix the security setting on your domain then redploy.'
    }
}


############################################################################################
# Session Host Batching Output
############################################################################################
# sessionHosts.bicep file can only support 113 virtual machines in each nested deployment
# 3 static resources
# 7 looped resources
# (7 * 113) + 3 = 794 resources; limit is 800 resources per deployment
# BATCH determines how many virtual machines will be deployed in each deployment
# INDEX determines the number of the first virtual machine in each batch that will be deployed
if($Count -gt 113)
{
    $DivisionValue = [math]::Truncate($Count / 113)
    $RemainderValue = $Count % 113
    $Batches = @()
    $Indexes = @()
    for($i = 0; $i -lt $DivisionValue; $i++)
    {
        # Add first batch manually
        $Batches += 113
        
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
                $Indexes += ((113 * $i) + $Index) - 1
            }
            else
            {
                # Create indexes when Index is greater than 0; no offset required
                $Indexes += (113 * $i) + $Index
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
            $Indexes += ((113 * $DivisionValue) + $Index) - 1
        }
        else
        {
            # Create remainder index when Index is greater than 0; no offset required
            $Indexes += (113 * $DivisionValue) + $Index
        }
    }
}
else 
{
    $Batches = @($Count)
    $Indexes = @($Index)
}
$DeploymentScriptOutputs["sessionHostBatches"] = $Batches
$DeploymentScriptOutputs["sessionHostIndexes"] = $Indexes


############################################################################################
# Azure NetApp Files Validation
############################################################################################
if($FSLogixStorage -like "AzureNetAppFiles*")
{
    $Vnet = Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $VnetResourceGroupName
    $DnsServers = "$($Vnet.DhcpOptions.DnsServers[0]),$($Vnet.DhcpOptions.DnsServers[1])"
    $SubnetId = ($Vnet.Subnets | Where-Object {$_.Delegations[0].ServiceName -eq "Microsoft.NetApp/volumes"}).Id
    Install-Module -Name "Az.NetAppFiles" -Force
    $DeployAnfAd = "true"
    $Accounts = Get-AzResource -ResourceType "Microsoft.NetApp/netAppAccounts" | Where-Object {$_.Location -eq $Location}
    foreach($Account in $Accounts)
    {
        $AD = Get-AzNetAppFilesActiveDirectory -ResourceGroupName $Account.ResourceGroupName -AccountName $Account.Name
        if($AD.ActiveDirectoryId){$DeployAnfAd = "false"}
    }
    $DeploymentScriptOutputs["dnsServers"] = $DnsServers
    $DeploymentScriptOutputs["subnetId"] = $SubnetId
    $DeploymentScriptOutputs["anfAd"] = $DeployAnfAd
}


############################################################################################
# Outputs
############################################################################################
$DeploymentScriptOutputs["acceleratedNetworking"] = ($Sku.capabilities | Where-Object {$_.name -eq 'AcceleratedNetworkingEnabled'}).value