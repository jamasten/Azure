param Location string
param LogicAppName string
param Tags object
@secure()
param WebhookUri string


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
              TenantId: subscription().tenantId
              SubscriptionId: subscription().subscriptionId
              EnvironmentName: environment().name
            }
          }
        }
      }
      triggers: {
        Recurrence: {
          type: 'Recurrence'
          recurrence: {
            frequency: 'Hour'
            interval: 6
            startTime: '2022-01-01T06:00:00'
            timeZone: 'Eastern Standard Time'
          }
        }
      }
    }
  }
}
