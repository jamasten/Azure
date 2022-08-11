[CmdletBinding()]
param (
  [parameter(Mandatory)]
  [string]$SubnetName,

  [parameter(Mandatory)]
  [string]$VirtualNetworkName,

  [parameter(Mandatory)]
  [string]$VirtualNetworkResourceGroupName
)

$VNET = Get-AzVirtualNetwork `
  -Name $VirtualNetworkName `
  -ResourceGroupName $VirtualNetworkResourceGroupName

$PrivateLinkNetworkPolicy = ($VNET | Select-Object -ExpandProperty 'Subnets' | Where-Object  {$_.Name -eq $SubnetName}).privateLinkServiceNetworkPolicies

if($PrivateLinkNetworkPolicy -eq 'Enabled')
{
  ($VNET | Select-Object -ExpandProperty 'Subnets' | Where-Object  {$_.Name -eq $SubnetName}).privateLinkServiceNetworkPolicies = 'Disabled'  
  $VNET | Set-AzVirtualNetwork
}