param Location string
param ManagedIdentityName string
param ResourceGroupNames array
param Timestamp string
param VnetName string

resource dnsFix 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'DnsAndAdminGroup'
  location: Location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', ManagedIdentityName)}': {}
    }
  }
  properties: {
    forceUpdateTag: Timestamp
    azPowerShellVersion: '5.4'
    arguments: '-ResourceGroupName ${ResourceGroupNames[1]} -VnetName ${VnetName}'
    scriptContent: 'param([string] [parameter(Mandatory=$true)] $ResourceGroupName, [string] [parameter(Mandatory=$true)] $VnetName);Start-Sleep 300;$vnet = Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $ResourceGroupName;$subnet = Get-AzVirtualNetworkSubnetConfig -Name \'AzureADDSSubnet\' -VirtualNetwork $vnet;if ($null -ne $subnet.IpConfigurations){$dnsIPs = @();foreach ($ipconfig in $subnet.IpConfigurations) {$RG = $ipconfig.Id.Split(\'/\')[4];$NIC = $ipconfig.Id.Split(\'/\')[8];$IP = (Get-AzNetworkInterface -Name $NIC -ResourceGroupName $RG).IpConfigurations.PrivateIpAddress;$dnsIPs += $IP}};$obj = new-object -type PSObject -Property @{\'DnsServers\' = $dnsIPs};$vnet.DhcpOptions = $obj;$vnet | Set-AzVirtualNetwork | Out-Null;$DeploymentScriptOutputs = @{};'
    timeout: 'PT4H'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}
