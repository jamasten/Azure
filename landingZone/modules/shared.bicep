param AutomationAccountName string
param KeyVaultName string
param Location string
param LogAnalyticsWorkspaceName string
param ManagedIdentityPrincipalId string
param UserObjectId string
@secure()
param VmPassword string
param VmUsername string


resource keyVault 'Microsoft.KeyVault/vaults@2016-10-01' = {
  name: KeyVaultName
  location: Location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: UserObjectId
        permissions: {
          keys: [
            'encrypt'
            'decrypt'
            'wrapKey'
            'unwrapKey'
            'sign'
            'verify'
            'get'
            'list'
            'create'
            'update'
            'import'
            'delete'
            'backup'
            'restore'
            'recover'
            'purge'
          ]
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'backup'
            'restore'
            'recover'
            'purge'
          ]
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: ManagedIdentityPrincipalId
        permissions: {
          keys: [
            'encrypt'
            'decrypt'
            'wrapKey'
            'unwrapKey'
            'sign'
            'verify'
            'get'
            'list'
            'create'
            'update'
            'import'
            'delete'
            'backup'
            'restore'
            'recover'
            'purge'
          ]
          secrets: [
            'get'
            'list'
            'set'
            'delete'
            'backup'
            'restore'
            'recover'
            'purge'
          ]
        }
      }
    ]
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
  }
  dependsOn: []
}

resource secret1 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  parent: keyVault
  name: 'VmPassword'
  tags: {}
  properties: {
    value: VmPassword
  }
}

resource secret2 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  parent: keyVault
  name: 'VmUsername'
  tags: {}
  properties: {
    value: VmUsername
  }
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2015-10-31' = {
  name: AutomationAccountName
  location: Location
  tags: {}
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

resource law 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: LogAnalyticsWorkspaceName
  location: Location
  tags: {}
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}
