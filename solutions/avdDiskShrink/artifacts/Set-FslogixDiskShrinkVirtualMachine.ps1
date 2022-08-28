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

# Deploy the virtual machine & run the tool
New-AzResourceGroupDeployment -ResourceGroupName $ManagementResourceGroup -TemplateSpecId

# Delete the virtual machine

