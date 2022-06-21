@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainServices string
param KerberosEncryptionType string
param Location string
param ManagementVmName string
param Netbios string
param OuPath string
param SasToken string
param ScriptsUri string
param SecurityPrincipalNames array
param StorageCount int
param StorageIndex int
param StorageAccountPrefix string
param StorageAccountResourceGroupName string
param Tags object
param Timestamp string


var SecurityPrincipalNamesString = string(SecurityPrincipalNames)


resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: '${ManagementVmName}/CustomScriptExtension'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${ScriptsUri}New-DomainJoinStorageAccount.ps1${SasToken}'
      ]
      timestamp: Timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File New-DomainJoinStorageAccount.ps1 -DomainJoinPassword "${DomainJoinPassword}" -DomainJoinUserPrincipalName ${DomainJoinUserPrincipalName} -DomainServices ${DomainServices} -Environment ${environment().name} -KerberosEncryptionType ${KerberosEncryptionType} -Netbios ${Netbios} -OuPath "${OuPath}" -SecurityPrincipalNames "${SecurityPrincipalNamesString}" -StorageCount ${StorageCount} -StorageIndex ${StorageIndex} -StorageAccountPrefix ${StorageAccountPrefix} -StorageAccountResourceGroupName ${StorageAccountResourceGroupName} -StorageSuffix ${environment().suffixes.storage} -SubscriptionId ${subscription().subscriptionId} -TenantId ${subscription().tenantId}'
    }
  }
}
