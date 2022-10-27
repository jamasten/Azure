[Cmdletbinding()]
Param(
    [parameter(Mandatory)]
    [string]
    $WorkspaceId,

    [parameter(Mandatory)]
    [string]
    $WorkspaceKey
)


##############################################################
#  Dual-home Microsoft Monitoring Agent for Azure Sentinel
##############################################################
$mma = New-Object -ComObject 'AgentConfigManager.MgmtSvcCfg'
$mma.AddCloudWorkspace($WorkspaceId, $WorkspaceKey)
$mma.ReloadConfiguration()
