param AvailabilitySetCount int
param AvailabilitySetNamePrefix string
param Location string
param Tags object


resource availabilitySet 'Microsoft.Compute/availabilitySets@2019-07-01' = [for i in range(0, AvailabilitySetCount): {
  name: '${AvailabilitySetNamePrefix}${i}'
  location: Location
  tags: Tags
  sku: {
    name: 'Aligned'
  }
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
  }
}]
