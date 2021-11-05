@secure()
param DomainJoinPassword string
param DomainJoinUserPrincipalName string
param DomainName string
param DomainServices string
param HostPoolName string
param KerberosEncryptionType string
param Location string
param Netbios string
param OuPath string
param ResourceNameSuffix string
param SecurityPrincipalId string
param SecurityPrincipalName string
param StorageAccountName string
param StorageAccountSku string
param Subnet string
param Tags object
param Timestamp string
param VirtualNetwork string
param VirtualNetworkResourceGroup string
param VmName string

@secure()
param VmPassword string
param VmUsername string

var NicName = 'nic-${ResourceNameSuffix}-mgt'
var ResourceGroupName = resourceGroup().name
var RoleAssignmentName = guid(StorageAccountName, '0')
var RoleAssignmentName_Users = guid('${StorageAccountName}/default/${HostPoolName}', '0')
var VmNameFull = '${VmName}mgt'

resource nic 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: NicName
  location: Location
  tags: Tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(subscription().subscriptionId, VirtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetwork, Subnet)
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: VmNameFull
  location: Location
  tags: Tags
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'None'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
      dataDisks: []
    }
    osProfile: {
      computerName: VmNameFull
      adminUsername: VmUsername
      adminPassword: VmPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    licenseType: 'Windows_Server'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource jsonADDomainExtension 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  parent: vm
  name: 'JsonADDomainExtension'
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
    }
    protectedSettings: {
      Password: DomainJoinPassword
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: StorageAccountName
  location: Location
  tags: Tags
  sku: {
    name: StorageAccountSku
  }
  kind: ((split(StorageAccountSku, '_')[0] == 'Standard') ? 'StorageV2' : 'FileStorage')
  properties: {
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    azureFilesIdentityBasedAuthentication: {
      directoryServiceOptions: ((DomainServices == 'AzureActiveDirectory') ? 'AADDS' : 'None')
    }
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = if (DomainServices == 'ActiveDirectory') {
  scope: storageAccount
  name: RoleAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
    principalId: reference(vm.id, '2020-12-01', 'Full').identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource roleAssignment_Users 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: storageAccount
  name: RoleAssignmentName_Users
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb')
    principalId: SecurityPrincipalId
  }
  dependsOn: [
    roleAssignment
  ]
}

resource storageAccount_FileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-02-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: false
    }
  }
  dependsOn: [
    roleAssignment
  ]
}

resource storageAccount_FileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-02-01' = {
  parent: storageAccount_FileServices
  name: toLower(HostPoolName)
  tags: Tags
  properties: {
    accessTier: (StorageAccountSku == 'Premium_LRS') ? 'Premium' : 'TransactionOptimized'
    shareQuota: 100
    enabledProtocols: 'SMB'
  }
  dependsOn: [
    storageAccount
    roleAssignment
  ]
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  parent: vm
  name: 'CustomScriptExtension'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/avd/scripts/New-DomainJoinStorageAccount.ps1'
      ]
      timestamp: Timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File New-DomainJoinStorageAccount.ps1 -DomainJoinPassword ${DomainJoinPassword} -DomainJoinUserPrincipalName ${DomainJoinUserPrincipalName} -DomainServices ${DomainServices} -Environment ${environment().name} -HostPoolName ${HostPoolName} -KerberosEncryptionType ${KerberosEncryptionType} -Netbios ${Netbios} -OuPath \'${OuPath}\' -ResourceGroupName ${ResourceGroupName} -SecurityPrincipalName \'${SecurityPrincipalName}\' -StorageAccountName ${StorageAccountName} -StorageKey ${listKeys(storageAccount.id, '2019-06-01').keys[0].value} -SubscriptionId ${subscription().subscriptionId} -TenantId ${subscription().tenantId}'
    }
  }
  dependsOn: [
    jsonADDomainExtension
    roleAssignment
    storageAccount_FileServices
    storageAccount_FileShare
  ]
}

output StorageAccountName string = storageAccount.name
