param AvailabilitySetCount int
param AvailabilitySetIndex int
param AvailabilitySetPrefix string
param Location string
param Tags object


resource availabilitySet 'Microsoft.Compute/availabilitySets@2019-07-01' = [for i in range(0, AvailabilitySetCount): {
  name: '${AvailabilitySetPrefix}${padLeft((i + AvailabilitySetIndex), 2, '0')}'
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
