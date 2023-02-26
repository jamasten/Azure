param HostPoolName string


resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2022-09-09' existing = {
  name: HostPoolName
}


output Location string = hostPool.location
output Properties object = hostPool.properties
output Tags object = hostPool.tags
output VMTemplate object = json(hostPool.properties.vmTemplate)
