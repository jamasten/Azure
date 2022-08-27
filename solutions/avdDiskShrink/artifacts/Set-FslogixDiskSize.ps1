[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory)]
	$WebHookData
)

$Parameters = ConvertFrom-Json -InputObject $WebHookData.RequestBody
$Environment = $Parameters.PSObject.Properties['Environment'].Value
$FileSharePath = $Parameters.PSObject.Properties['FileSharePath'].Value
$ResourceGroupName = $Parameters.PSObject.Properties['ResourceGroupName'].Value
$StorageAccountName = $Parameters.PSObject.Properties['StorageAccountName'].Value
$SubscriptionId = $Parameters.PSObject.Properties['SubscriptionId'].Value

$ErrorActionPreference = 'Stop'

#Connect to Azure and Import Az Module
Import-Module -Name 'Az.Accounts'
Import-Module -Name 'Az.Storage'
Connect-AzAccount -Environment $Environment -Subscription $SubscriptionId -Identity | Out-Null


Write-Output "[$StorageAccountName] [$FileShareName] Share Capacity: $($ProvisionedCapacity)GB"
Write-Output "[$StorageAccountName] [$FileShareName] Share Usage: $([math]::Round($UsedCapacity/1GB, 0))GB"

# Get storage account
$StorageAccount = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName
