[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory)]
	$WebHookData
)

$ErrorActionPreference = 'Stop'

try 
{
	# Import required modules
	Import-Module -Name 'Az.Accounts'
	Import-Module -Name 'Az.KeyVault'
	Import-Module -Name 'Az.Resources'
	Write-Output 'Imported modules successfully'

	# Get variable & parameter values from webhook data
	$Parameters = ConvertFrom-Json -InputObject $WebHookData.RequestBody
	$Environment = $Parameters.PSObject.Properties['Environment'].Value
	$KeyVaultName = $Parameters.PSObject.Properties['KeyVaultName'].Value
	$ResourceGroupName = $Parameters.PSObject.Properties['ResourceGroupName'].Value
	$SubscriptionId = $Parameters.PSObject.Properties['SubscriptionId'].Value
	$Tags = $Parameters.PSObject.Properties['Tags'].Value
	$TemplateSpecId = $Parameters.PSObject.Properties['TemplateSpecId'].Value
	$TenantId = $Parameters.PSObject.Properties['TenantId'].Value

	# Convert Tags from PSCustomObject to HashTable
	$FixedTags = @{}
	$Tags.psobject.properties | Foreach { $FixedTags[$_.Name] = $_.Value }
	Write-Output 'Fixed tags successfully'

	$Params = @{
		ResourceGroupName = $ResourceGroupName
		TemplateSpecId = $TemplateSpecId
		_artifactsLocation = $Parameters.PSObject.Properties['_artifactsLoction'].Value
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
		VmName = $Parameters.PSObject.Properties['VmName'].Value
		VmSize = $Parameters.PSObject.Properties['VmSize'].Value
	}


	Connect-AzAccount -Environment $Environment -Tenant $TenantId -Subscription $SubscriptionId -Identity | Out-Null
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
	Write-Output 'Deployed virtual machine successfully'

	# Delete the virtual machine
	Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
	Write-Output 'Removed virtual machine successfully'
}
catch
{
	Write-Output $_.Exception
	throw
}