param Location string
param StorageAccountId string
param StorageAccountName string
param Subnet string
param Tags object
param VirtualNetwork string
param VirtualNetworkResourceGroup string

var PrivateDnsZoneName = 'privatelink.file.${StorageSuffix}'
var StorageSuffix = environment().suffixes.storage
var SubnetId = resourceId(VirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetwork, Subnet)


resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: PrivateDnsZoneName
  location: 'global'
  tags: Tags
  properties: {}
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-05-01' = {
  name: 'pe-${StorageAccountName}'
  location: Location
  tags: Tags
  properties: {
    subnet: {
      id: SubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-${StorageAccountName}_${guid(StorageAccountName)}'
        properties: {
          privateLinkServiceId:StorageAccountId
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpoint
  name: StorageAccountName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'ipconfig1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

resource virtualNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateDnsZone
  name: 'link-${VirtualNetwork}'
  location: 'global'
  tags: Tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resourceId(VirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks', VirtualNetwork)
    }
  }
}
