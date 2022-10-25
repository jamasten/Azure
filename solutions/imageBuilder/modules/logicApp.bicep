param ActionSettingsBody object
param Location string
param LogicAppName string
param TimeZone string
@secure()
param WebhookUri string

resource logicApp 'Microsoft.Logic/workflows@2016-06-01' = {
  name: LogicAppName
  location: Location
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
            body: ActionSettingsBody
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
