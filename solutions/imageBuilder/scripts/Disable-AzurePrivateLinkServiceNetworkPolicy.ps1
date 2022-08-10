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
   
($VNET | Select-Object -ExpandProperty 'Subnets' | Where-Object  {$_.Name -eq $SubnetName}).privateLinkServiceNetworkPolicies = "Disabled"  
 
$VNET | Set-AzVirtualNetwork