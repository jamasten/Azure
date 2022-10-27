[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory)]
	$WebHookData
)


$Parameters = ConvertFrom-Json -InputObject $WebHookData.RequestBody
$EnvironmentName = $Parameters.PSObject.Properties['EnvironmentName'].Value
$HostPoolName = $Parameters.PSObject.Properties['HostPoolName'].Value
$SubscriptionId = $Parameters.PSObject.Properties['SubscriptionId'].Value
$TenantId = $Parameters.PSObject.Properties['TenantId'].Value
$WorkspaceId = $Parameters.PSObject.Properties['WorkspaceId'].Value


$ErrorActionPreference = 'Stop'

try
{
    # Import Modules
    Import-Module -Name 'Az.Accounts','Az.Compute','Az.Resources'
    Write-Output "Imported required modules"

    # Connect to Azure using the Managed Identity
    Connect-AzAccount -Environment $EnvironmentName -Subscription $SubscriptionId -Tenant $TenantId -Identity | Out-Null
    Write-Output "Connected to Azure"

    $Query = "WVDConnections | where State == 'Connected' | where _ResourceId has $HostPoolName"

    $Results = Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $Query -Timespan (New-TimeSpan -Days 90) | `
    Select-Object -ExpandProperty Results
    
    
}
catch 
{
    Write-Output $_.Exception
    throw
}