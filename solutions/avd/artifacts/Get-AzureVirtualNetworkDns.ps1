param(
    [parameter(Mandatory)]
    [string]$Subnet, 
    
    [parameter(Mandatory)]
    [string]$VirtualNetwork, 
    
    [parameter(Mandatory)]
    [string]$VirtualNetworkResourceGroup
)

$Dns = (Get-AzVirtualNetwork -Name $VirtualNetwork -ResourceGroupName $VirtualNetworkResourceGroup).DhcpOptions.DnsServers
$DeploymentScriptOutputs = @{}
$DeploymentScriptOutputs['dns'] = $Dns