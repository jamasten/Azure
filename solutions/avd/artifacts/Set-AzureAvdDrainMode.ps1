param(
    [Parameter(Mandatory)]
    [string]$HostPool,
    
    [Parameter(Mandatory)]
    [string]$ResourceGroup
)

$SessionHosts = (Get-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPool).Name
foreach($SessionHost in $SessionHosts)
{
    $Name = ($SessionHost -split '/')[1]
    Update-AzWvdSessionHost -ResourceGroupName $ResourceGroup -HostPoolName $HostPool -Name $Name -AllowNewSession:$False
}
$DeploymentScriptOutputs = @{}