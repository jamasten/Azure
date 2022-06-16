param IPAddress string
param Location string
param NicName string
param SubnetId string

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: NicName
  location: Location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: IPAddress
          subnet: {
            id: SubnetId
          }
        }
      }
    ]
  }
}
