param IpAddress string
param Location string
param NicName string
param SubnetId string
param Tags object


resource nic 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: NicName
  location: Location
  tags: Tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: IpAddress
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: SubnetId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}
