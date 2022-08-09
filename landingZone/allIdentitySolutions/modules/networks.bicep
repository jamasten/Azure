param Location string
param ManagedIdentityName string
param NetworkContributorId string
param NetworkWatcherName string
param PrincipalId string
param VnetName string


var RoleAssignmentName = guid(resourceGroup().name, ManagedIdentityName, NetworkContributorId)


resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: RoleAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
    principalId: PrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource networkWatcher 'Microsoft.Network/networkWatchers@2021-02-01' = {
  name: NetworkWatcherName
  location: Location
  properties: {}
}

resource adds_subnet 'Microsoft.Network/networkSecurityGroups@2020-11-01' = {
  name: 'adds-subnet'
  location: Location
  properties: {
    securityRules: [
      {
        name: 'AllowSyncWithAzureAD'
        properties: {
          access: 'Allow'
          destinationAddressPrefixes: []
          priority: 101
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureActiveDirectoryDomainServices'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          destinationPortRanges: []
          sourcePortRanges: []
          destinationApplicationSecurityGroups: []
          sourceApplicationSecurityGroups: []
        }
      }
      {
        name: 'AllowPSRemoting'
        properties: {
          access: 'Allow'
          destinationAddressPrefixes: []
          priority: 301
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureActiveDirectoryDomainServices'
          sourcePortRange: '*'
          sourcePortRanges: []
          destinationAddressPrefix: '*'
          destinationPortRange: '5986'
          destinationPortRanges: []
          destinationApplicationSecurityGroups: []
          sourceApplicationSecurityGroups: []
        }
      }
      {
        name: 'AllowRD'
        properties: {
          access: 'Allow'
          destinationAddressPrefixes: []
          priority: 201
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: 'CorpNetSaw'
          sourcePortRange: '*'
          sourcePortRanges: []
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
          destinationPortRanges: []
          destinationApplicationSecurityGroups: []
          sourceApplicationSecurityGroups: []
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = [for i in range(0, 3): {
  name: '${VnetName}-00${i}'
  location: Location
  tags: {}
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/21'
      ]
    }
    subnets: [
      {
        name: 'AzureADDSSubnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          delegations: []
          networkSecurityGroup: {
            id: adds_subnet.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          serviceEndpoints: []
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'AzureNetAppFiles'
        properties: {
          addressPrefix: '10.0.2.0/24'
          delegations: [
            {
              name: 'Microsoft.Netapp.Volumes'
              properties: {
                serviceName: 'Microsoft.Netapp/volumes'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'SharedServices'
        properties: {
          addressPrefix: '10.0.3.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'Servers'
        properties: {
          addressPrefix: '10.0.4.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'Clients'
        properties: {
          addressPrefix: '10.0.5.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
    enableVmProtection: false
  }
  dependsOn: [
    networkWatcher
  ]
}]
