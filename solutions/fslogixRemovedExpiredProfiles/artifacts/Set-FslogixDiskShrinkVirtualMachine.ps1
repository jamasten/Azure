[CmdletBinding(SupportsShouldProcess)]
param(
    [parameter(Mandatory)]
    [int]
    $DeleteOlderThanDays,

	[Parameter(Mandatory)]
	[string]
	$EnvironmentName,

	[Parameter(Mandatory)]
	[string]
	$KeyVaultName,

	[Parameter(Mandatory)]
	[string]
	$ResourceGroupName,

	[Parameter(Mandatory)]
	[string]
	$SubscriptionId,

	[Parameter(Mandatory)]
	$Tags,

	[Parameter(Mandatory)]
	[string]
	$TemplateSpecId,

	[Parameter(Mandatory)]
	[string]
	$TenantId,

	[Parameter(Mandatory)]
	[string]
	$VmName
)

$ErrorActionPreference = 'Stop'

try 
{
	# Import required modules
	Import-Module -Name 'Az.Accounts'
	Import-Module -Name 'Az.KeyVault'
	Import-Module -Name 'Az.Resources'
	Write-Output 'Imported modules successfully'

	# Convert Tags from PSCustomObject to HashTable
	$FixedTags = @{}
	$Tags.psobject.properties | ForEach-Object { $FixedTags[$_.Name] = $_.Value }
	Write-Output 'Fixed tags successfully'

	$Params = @{
		ResourceGroupName = $ResourceGroupName
		TemplateSpecId = $TemplateSpecId
		_artifactsLocation = $Parameters.PSObject.Properties['_artifactsLoction'].Value
		DeleteOlderThanDays = $Parameters.PSObject.Properties['DeleteOlderThanDays'].Value
		DiskName = $Parameters.PSObject.Properties['DiskName'].Value
		FileShareNames = "$($Parameters.PSObject.Properties['FileShareNames'].Value)"
		HybridUseBenefit = $Parameters.PSObject.Properties['HybridUseBenefit'].Value
		KeyVaultName = $KeyVaultName
		Location = $Parameters.PSObject.Properties['Location'].Value
		NicName = $Parameters.PSObject.Properties['NicName'].Value
		StorageAccountNames = "$($Parameters.PSObject.Properties['StorageAccountNames'].Value)"
		StorageAccountSuffix  = $Parameters.PSObject.Properties['StorageAccountSuffix'].Value
		Subnet = $Parameters.PSObject.Properties['SubnetName'].Value
		Tags = $FixedTags
		UserAssignedIdentityClientId = $Parameters.PSObject.Properties['UserAssignedIdentityClientId'].Value
		UserAssignedIdentityResourceId = $Parameters.PSObject.Properties['UserAssignedIdentityResourceId'].Value
		VirtualNetwork = $Parameters.PSObject.Properties['VirtualNetworkName'].Value
		VirtualNetworkResourceGroup = $Parameters.PSObject.Properties['VirtualNetworkResourceGroupName'].Value
		VmName = $VmName
		VmSize = $Parameters.PSObject.Properties['VmSize'].Value
	}


	Connect-AzAccount -Environment $EnvironmentName -Tenant $TenantId -Subscription $SubscriptionId -Identity | Out-Null
	Write-Output 'Connected to Azure Successfully'

	# Get secure strings from Key Vault and add the values using the Add method for proper deserialization
	$SasToken = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'SasToken').SecretValue
	if($SasToken)
	{
		$Params.Add('_artifactsLocationSasToken', $SasToken)
	}
	$VmPassword = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'VmPassword').SecretValue
	$Params.Add('VmPassword', $VmPassword)
	$VmUsername = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'VmUsername').SecretValue
	$Params.Add('VmUsername', $VmUsername)
	Write-Output 'Acquired Key Vault secrets successfully'

	# Deploy the virtual machine & run the tool
	New-AzResourceGroupDeployment @Params
	Write-Output 'Success: removed expired FSLogix profiles'

	# Delete the virtual machine
	Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Force
	Write-Output 'Removed virtual machine successfully'
}
catch
{
	Write-Output 'Error: Failed to remove expired FSLogix profiles'
	Write-Output $_.Exception
	throw
}