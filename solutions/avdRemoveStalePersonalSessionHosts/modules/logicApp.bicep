param HostPoolName string
param HostPoolResourceGroupName string
param Location string
param LogicAppName string
param SessionHostExpirationInDays int
param Tags object
param TimeZone string
@secure()
param WebhookUri string
param WorkspaceId string


// Logic App to trigger scaling runbook for the AVD host pool
resource logicApp_ScaleHostPool 'Microsoft.Logic/workflows@2016-06-01' = {
  name: LogicAppName
  location: Location
  tags: Tags
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        HTTP: {
          type: 'Http'
          inputs: {
            method: 'POST'
            uri: WebhookUri
            body: {
              EnvironmentName: environment().name
              HostPoolName: HostPoolName
              HostPoolResourceGroupName: HostPoolResourceGroupName
              SessionHostExpirationInDays: SessionHostExpirationInDays
              SubscriptionId: subscription().subscriptionId
              TenantId: subscription().tenantId
              WorkspaceId: WorkspaceId
            }
          }
        }
      }
      triggers: {
        Recurrence: {
          type: 'Recurrence'
          recurrence: {
            frequency: 'Day'
            interval: 1
            startTime: '2022-01-01T23:00:00'
            timeZone: TimeZone
          }
        }
      }
    }
  }
}
