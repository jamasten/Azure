<#
.SYNOPSIS

Updates or Enables Diagnostics Settings on Azure Resources

.DESCRIPTION

This script finds all the resources in your subscription.  Then loops through each
resource and ensure all the log and metric settings are enabled.  If a setting is 
not fully enabled, the script will delete the diagnostic setting.  Then if the 
diagnostic setting was deleted or did not exist, all the logs and metrics are enabled
and sent to the specifed log analytics workspace.

.PARAMETER WorkspaceResourceId

Specifies Resource ID of the Log Analytics Workspace used for storing the diagnotics data.

.INPUTS

None. You cannot pipe objects to Set-AzureResourceDiagnostics.ps1.

.OUTPUTS

The OUTPUT from this script will provide details about resources that are not supported and
when resources are configured with diagnostic settings.

.EXAMPLE

PS> .\Set-AzureResourceDiagnostics.ps1 -WorkspaceResourceId "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/rg-shared-d-eastus/providers/microsoft.operationalinsights/workspaces/law-d-eastus"
#>

Param(
    # Resource ID for Log Analytics Workspace
    # Found on the Properties blade in the Portal
    [parameter(Mandatory)][string]$WorkspaceResourceId
)

# Ensure the Insight provider is enabled on your Azure subscription
$ProviderState = (Get-AzResourceProvider -ProviderNamespace 'microsoft.insights').RegistrationState
if($ProviderState -contains 'NotRegistered')
{
    Throw 'The required resource provider, "microsoft.insignts", needs to be enabled on your subscription.'
}

# Gets all the resources in your subscriptions
$Resources = Get-AzResource

foreach($Resource in $Resources)
{
    Write-Host ''
    
    # Checks the Diagnostic Setting status for the current resource
    $Status = Get-AzDiagnosticSetting -ResourceId $Resource.Id -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    
    # Condition checks if any of the Logs and / or Metrics are disabled in the Diagnostic Setting
    if($Status.Logs.Enabled -contains $false -or $Status.Metrics.Enabled -contains $false)
    {
        # Removes the Diagnostic Setting for the current resource
        Remove-AzDiagnosticSetting -ResourceId $Resource.Id -Verbose -WarningAction SilentlyContinue
    }
    
    # Condition checks if the Diagnostic Setting doesn't exist or if any of the Logs and / or Metrics are disabled in the Diagnostic Setting
    if($Status -eq $null -or $Status.Logs.Enabled -contains $false -or $Status.Metrics.Enabled -contains $false)
    {
        try
        {
            # Enables all Logs and / or Metrics on the current resource, if supported
            Set-AzDiagnosticSetting -ResourceId $Resource.Id -Name ('diag-' + $Resource.Name) -Enabled $true -WorkspaceId $WorkspaceResourceId -ExportToResourceSpecific -Verbose -WarningAction SilentlyContinue -ErrorAction Stop
        }
        catch [System.Management.Automation.PSInvalidOperationException]
        {   
            # this block catches any resources that do not support Diagnostic Settings and outputs the statement below
            Write-Host "$($Resource.Name) does not support Diagnostic Settings"
        }
        catch
        {
            # if an error is thrown, this block outputs all the properties of the error message
            $_ | Select-Object *
        }
    }
}