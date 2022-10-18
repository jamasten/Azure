param(

    [parameter]
    [string]$MicrosoftMonitoringAgent,

    [parameter]
    [string]$SentinelWorkspaceId,

    [parameter]
    [string]$SentinelWorkspaceKey

)


##############################################################
#  Dual-home Microsoft Monitoring Agent for Azure Sentinel
##############################################################
if($MicrosoftMonitoringAgent -eq 'true' -and $SentinelWorkspaceId -ne 'NotApplicable' -and $SentinelWorkspaceKey -ne 'NotApplicable')
{
    $mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
    $mma.AddCloudWorkspace($SentinelWorkspaceId, $SentinelWorkspaceKey)
    $mma.ReloadConfiguration()
}


##############################################################
#  Run the Virtual Desktop Optimization Tool (VDOT)
##############################################################
# https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool

# Extract VDOT from ZIP archive
Expand-Archive -LiteralPath 'main.zip' -Force -ErrorAction 'Stop'
    
# Run VDOT
& .\main\Virtual-Desktop-Optimization-Tool-main\Windows_VDOT.ps1 -Optimizations All -AcceptEULA -Restart