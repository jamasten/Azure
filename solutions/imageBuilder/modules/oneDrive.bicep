param DeploymentScriptName string
param Location string
param StorageAccountName string
param StorageAccountResourceGroupName string
param StorageContainerName string
param Tags object


var FileName = 'tenantId.txt'


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-01-01' existing = {
  name: StorageAccountName
  scope: resourceGroup(StorageAccountResourceGroupName)
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: '${DeploymentScriptName}-onedrive'
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
        value: subscription().tenantId
      }
    ]
    scriptContent: 'echo "$CONTENT" > ${FileName} && az storage blob upload -f ${FileName} -c ${StorageContainerName} -n ${FileName}'
  }
}
