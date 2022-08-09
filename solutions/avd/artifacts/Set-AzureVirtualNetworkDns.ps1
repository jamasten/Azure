param(
    [parameter(Mandatory)]
    [string]$Dns, 
    
    [parameter(Mandatory)]
    [string]$VirtualNetwork, 
    
    [parameter(Mandatory)]
    [string]$VirtualNetworkResourceGroup
)

$Vnet = Get-AzVirtualNetwork -ResourceGroupName $VirtualNetworkResourceGroup -Name $VirtualNetwork
$Obj = New-Object -Type 'PSObject' -Property @{'DnsServers' = $Dns}
$Vnet.DhcpOptions = $Obj
$Vnet | Set-AzVirtualNetwork | Out-Null