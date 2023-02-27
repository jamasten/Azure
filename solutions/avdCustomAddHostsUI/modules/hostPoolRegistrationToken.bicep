param HostPoolName string
param HostPoolType string
param LoadBalancerType string
param Location string
param PreferredAppGroupType string
param Tags object
param Timestamp string = utcNow('u')


resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2022-09-09' = {
  name: HostPoolName
  location: Location
  tags: Tags
  properties: {
    hostPoolType: HostPoolType
    loadBalancerType: LoadBalancerType
    preferredAppGroupType: PreferredAppGroupType
    registrationInfo: {
      expirationTime: dateTimeAdd(Timestamp, 'PT2H')
      registrationTokenOperation: 'Update'
    }
  }
}
