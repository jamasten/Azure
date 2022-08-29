[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory)]
	$WebHookData
)

# Get parameter values from webhook data
$Parameters = ConvertFrom-Json -InputObject $WebHookData.RequestBody
$ResourceGroupName = $Parameters.PSObject.Properties['ResourceGroupName'].Value
$_artifactsLoction = $Parameters.PSObject.Properties['_artifactsLoction'].Value
$DiskName = $Parameters.PSObject.Properties['DiskName'].Value
$Environment = $Parameters.PSObject.Properties['Environment'].Value
$FileShareNames = $Parameters.PSObject.Properties['FileShareNames'].Value
$HybridUseBenefit =  $Parameters.PSObject.Properties['HybridUseBenefit'].Value
$KeyVaultName = $Parameters.PSObject.Properties['KeyVaultName'].Value
$Location = $Parameters.PSObject.Properties['Location'].Value
$NicName = $Parameters.PSObject.Properties['NicName'].Value
$StorageAccountNames = $Parameters.PSObject.Properties['StorageAccountNames'].Value
$StorageAccountSuffix = $Parameters.PSObject.Properties['StorageAccountSuffix'].Value
$SubnetName = $Parameters.PSObject.Properties['SubnetName'].Value
$SubscriptionId = $Parameters.PSObject.Properties['SubscriptionId'].Value
$Tags = $Parameters.PSObject.Properties['Tags'].Value
$TemplateSpecId = $Parameters.PSObject.Properties[''].Value
$TenantId = $Parameters.PSObject.Properties['TenantId'].Value
$UserAssignedIdentityClientId = $Parameters.PSObject.Properties['UserAssignedIdentityClientId'].Value
$UserAssignedIdentityResourceId = $Parameters.PSObject.Properties['UserAssignedIdentityResourceId'].Value
$VirtualNetworkName = $Parameters.PSObject.Properties['VirtualNetworkName'].Value
$VirtualNetworkResourceGroupName = $Parameters.PSObject.Properties['VirtualNetworkResourceGroupName'].Value
$VmName = $Parameters.PSObject.Properties['VmName'].Value
$VmSize = $Parameters.PSObject.Properties['VmSize'].Value

$ErrorActionPreference = 'Stop'

# Convert JSON to PowerShell
[array]$FileShareNames = $FileShareNames.Replace("'",'"') | ConvertFrom-Json
[array]$StorageAccountNames = $StorageAccountNames.Replace("'",'"') | ConvertFrom-Json
[psobject] $Tags = $Tags.Replace("'",'"') | ConvertFrom-Json

# Build hashtable of parameters for splatting
$Params = @{
	_artifactsLoction = $_artifactsLoction;
	DiskName = $DiskName;
	FileShareNames = $FileShareNames;
	HybridUseBenefit = $HybridUseBenefit;
	KeyVaultName = $KeyVaultName;
	Location = $Location;
	NicName = $NicName;
	StorageAccountNames = $StorageAccountNames;
	StorageAccountSuffix =  $StorageAccountSuffix;
	Subnet = $SubnetName;
	Tags = $Tags;
	UserAssignedIdentityClientId = $UserAssignedIdentityClientId;
	UserAssignedIdentityResourceId = $UserAssignedIdentityResourceId;
	VirtualNetwork = $VirtualNetworkName;
	VirtualNetworkResourceGroup = $VirtualNetworkResourceGroupName;
	VmName = $VmName;
	VmSize = $VmSize;
}

# Get secure strings from Key Vault and add the values using the Add method for proper deserialization
Connect-AzAccount -Environment $Environment -Tenant $TenantId -Subscription $SubscriptionId -Identity
$SasToken = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'SasToken').SecretValue
if($SasToken)
{
	$Params.Add('_artifactsLocationSasToken', $SasToken)
}
$VmPassword = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'VmPassword').SecretValue
$Params.Add('VmPassword', $VmPassword)
$VmUsername = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'VmUsername').SecretValue
$Params.Add('VmUsername', $VmUsername)

# Deploy the virtual machine & run the tool
New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateSpecId $TemplateSpecId @Params

# Delete the virtual machine
Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName
