param Location string
param PolicyId string
param RecoveryServicesVaultName string
param SessionHostCount int
param SessionHostIndex int
param Tags object
param VmName string
param VmResourceGroupName string


var v2VmContainer = 'iaasvmcontainer;iaasvmcontainerv2;'
var v2Vm = 'vm;iaasvmcontainerv2;'


resource protectedItems_Vm 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2021-08-01' = [for i in range(0, SessionHostCount): {
  name: '${RecoveryServicesVaultName}/Azure/${v2VmContainer}${VmResourceGroupName};${VmName}${padLeft((i + SessionHostIndex), 3, '0')}/${v2Vm}${VmResourceGroupName};${VmName}${padLeft((i + SessionHostIndex), 3, '0')}'
  location: Location
  tags: Tags
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: PolicyId
    sourceResourceId: resourceId(VmResourceGroupName, 'Microsoft.Compute/virtualMachines', '${VmName}${padLeft((i + SessionHostIndex), 3, '0')}')
  }
}]
