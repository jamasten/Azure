@secure()
param CommandToExecute string
param Location string
param ManagementVmName string
param SasToken string
param ScriptsUri string
param Tags object
param Timestamp string


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
        '${ScriptsUri}Set-NtfsPermissions.ps1${SasToken}'
      ]
      timestamp: Timestamp
    }
    protectedSettings: {
      commandToExecute: CommandToExecute
    }
  }
}
