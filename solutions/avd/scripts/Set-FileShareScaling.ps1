param(
	[parameter(Mandatory)]
	[string]$Environment,

	[parameter(Mandatory)]
	[string]$SubscriptionId,

	[parameter(Mandatory)]
	[string]$ResourceGroupName,

	[parameter(Mandatory)]
	[string]$StorageAccountName,

	[parameter(Mandatory)]
	[string]$FileShareName
)

$ErrorActionPreference = 'Stop'

#Connect to Azure and Import Az Module
Import-Module -Name Az.Accounts
Import-Module -Name Az.Storage
Connect-AzAccount -Environment $Environment -Subscription $SubscriptionId -Identity | Out-Null

# Get file share
$PFS = Get-AzRmStorageShare -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName -Name $FileShareName -GetShareUsage

# Get provisioned capacity and used capacity
$ProvisionedCapacity = $PFS.QuotaGiB
$UsedCapacity = $PFS.ShareUsageBytes
Write-Output "Share Capacity: $($ProvisionedCapacity)GB"
Write-Output "Share Usage: $([math]::Round($UsedCapacity/1GB, 0))GB"

# Get storage account
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName

# if less than 20% of provisioned capacity is remaining, increase provisioned capacity by 20%
if (($ProvisionedCapacity - ($UsedCapacity / ([Math]::Pow(2,30)))) -lt ($ProvisionedCapacity*0.2)) {
    Write-Output "Share Usage is greater than 80%" 
    $Quota = $ProvisionedCapacity*1.2
    Update-AzRmStorageShare -StorageAccount $StorageAccount -Name $FileShareName -QuotaGiB $Quota | Out-Null
    $ProvisionedCapacity = $Quota
    Write-Output "New Capacity: $($ProvisionedCapacity)GB"
}
else {
    Write-Output "Share Usage is below 20% threshold. No Changes."
}
