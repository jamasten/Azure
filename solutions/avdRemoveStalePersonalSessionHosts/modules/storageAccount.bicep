param ContainerName string
param DeploymentScriptName string
param Location string
param StorageAccountName string
param SubnetName string
param Tags object
param VirtualNetworkName string
param VirtualNetworkResourceGroupName string


var FileName = 'Remove-StaleHosts.ps1'


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: StorageAccountName
  location: Location
  tags: Tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: resourceId(VirtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetworkName, SubnetName)
          action: 'Allow'
        }
      ]
      ipRules: []
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-02-01' = {
  parent: storageAccount
  name: 'default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = {
  parent: blobService
  name: ContainerName
  properties: {
    publicAccess: 'None'
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: DeploymentScriptName
  location: Location
  tags: Tags
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.26.1'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccount.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: storageAccount.listKeys().keys[0].value
      }
      {
        name: 'CONTENT'
        value: loadTextContent('../artifacts/Remove-StaleHosts.ps1')
      }
    ]
    scriptContent: 'echo "$CONTENT" > ${FileName} && az storage blob upload -f ${FileName} -c ${container.name} -n ${FileName}'
  }
}
