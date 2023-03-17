@secure()
param DomainJoinPassword string
@secure()
param DomainJoinUserPrincipalName string
param DomainName string
param Location string
param SessionHostCount int
param SessionHostIndex int
param SessionHostOuPath string
param Tags object
param Timestamp string
param VirtualMachineNamePrefix string


resource jsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = [for i in range(0, SessionHostCount): {
  name: '${VirtualMachineNamePrefix}${padLeft((i + SessionHostIndex), 4, '0')}/JsonADDomainExtension'
  location: Location
  tags: Tags
  properties: {
    forceUpdateTag: Timestamp
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: DomainName
      User: DomainJoinUserPrincipalName
      Restart: 'true'
      Options: '3'
      OUPath: SessionHostOuPath
    }
    protectedSettings: {
      Password: DomainJoinPassword
    }
  }
}]
