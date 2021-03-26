# Scale WVD Session Hosts using Azure Automation

## STEP 1: Deploy the Automation Account

### Description

This ARM template will deploy the following resources:

* Automation Account
* Automation Account Modules
* Automation Account Runbook
* Automation Account Webhook
* Automation Account Variable
* Diagnostic Settings for the Automation Account (Optional)

By configuring the "workspace" parameters for this deployment, the Runbook job logs will be sent to a Log Analytics Workspace.  Review this Docs page, "[View Automation logs in Azure Monitor logs](https://docs.microsoft.com/en-us/azure/automation/automation-manage-send-joblogs-log-analytics#view-automation-logs-in-azure-monitor-logs)", for the KQL queries to view the log data and create alerts.

### Template Parameters

#### REQUIRED

* **AutomationAccountName**: Name of an existing Automation Account or the desired name for a new Automation Account
* **Version**: Choose between ARM and Classic version of WVD

#### OPTIONAL

* **WorkspaceName**: Name of the Log Analytics Workspace to use for logging the Runbook jobs in Azure Automation
* **WorkspaceResourceGroupName**: Resource Group Name of the Log Analytics Workspace to use for logging the Runbook jobs in Azure Automation

### Try with Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2FscalingAutomation%2FscalingAutomationAccount.json)
[![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2FscalingAutomation%2FscalingAutomationAccount.json)

### Try with PowerShell

````powershell
New-AzResourceGroupDeployment `
    -ResourceGroupName '<Resource Group Name>' `
    -TemplateFile 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/scalingAutomation/scalingAutomationAccount.json' `
    -AutomationAccountName '<Automation Account Name>' `
    -Version '<ARM or Classic>' `
    -WorkspaceName '<Log Analytics Workspace Name>' `
    -WorkspaceResourceGroupName '<Log Analytics Workspace Resource Group Name>' `
    -Verbose
````

### Try with CLI

````cli
az deployment group create \
    --resource-group '<Resource Group Name>' \
    --template-uri 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/scalingAutomation/scalingAutomationAccount.json' \
    --parameters \
        AutomationAccountName='<Automation Account Name>' \
        Version='<ARM or Classic>' \
        WorkspaceName='<Log Analytics Workspace Name>' \
        WorkspaceResourceGroupName='<Log Analytics Workspace Resource Group Name>'
````

## STEP 2: Create a Run As Account

https://docs.microsoft.com/en-us/azure/virtual-desktop/set-up-scaling-script#create-an-azure-automation-run-as-account

## STEP 3: Deploy the Logic App

### Description

This ARM template will deploy a Logic App to trigger the scaling runbook in Azure Automation.

### Template Parameters

#### REQUIRED

* **AutomationConnectionName**: Name of the Azure Automation Run As account
* **AutomationAccountName**: Name of the Automation Account
* **AutomationAccountResourceGroupName**: Name of the Resource Group for the Automation Account
* **BeginPeakTime**: Time when session hosts will scale up and continue to stay on to support peak demand; Format 24 hours, e.g. 9:00 for 9am
* **ClassicBrokerUrl**: Connection Broker URL for a Classic WVD deployment only. For ARM, either leave the value blank or input any string.
* **ClassicTenantGroupName**: Tenant Group Name for a Classic WVD deployment only. For ARM, either leave the value blank or input any string.
* **ClassicTenantName**: Tenant Name for a Classic WVD deployment only.For ARM, either leave the value blank or input any string.
* **EndPeakTime**: Time when session hosts will scale down and stay off to support low demand; Format 24 hours, e.g. 17:00 for 5pm
* **HostPoolName**: Name of the WVD host pool to target for scaling
* **HostPoolResourceGroupName**: Name of the resource group for the WVD host pool to target for scaling
* **LimitSecondsToForceLogOffUser**: The number of seconds to wait before automatically signing out users. If set to 0, any session host that has user sessions will be left untouched
* **LogicAppName**: Name for the new or existing Logic App
* **MaintenanceTagName**: The name of the Tag associated with VMs you don't want to be managed by this scaling tool
* **MinimumNumberOfRdsh**: The minimum number of session host VMs to keep running during off-peak hours
* **RecurrenceInterval**: Specifies the recurrence interval of the job in minutes
* **SessionThresholdPerCPU**: The maximum number of sessions per CPU that will be used as a threshold to determine when new session host VMs need to be started during peak hours
* **TimeDifference**: Time zone off set for host pool location; Format 24 hours, e.g. -4:00 for Eastern Daylight Time
* **Version**: Determines if the solution will scale a Classic or ARM version of a WVD host pool

#### OPTIONAL

* **LogAnalyticsWorkspaceId**: Log Analytics Workspace ID for collecting log data
* **LogAnalyticsPrimaryKey**: Log Analytics Primary Key for collecting log data
* **LogOffTitle**: The title of the message sent to the user before they are forced to sign out
* **LogOffMessage**: The body of the message sent to the user before they are forced to sign out

### Try with Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2FscalingAutomation%2FscalingLogicApp.json)
[![Deploy to Azure Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2FscalingAutomation%2FscalingLogicApp.json)

### Try with PowerShell

````powershell
New-AzResourceGroupDeployment `
    -ResourceGroupName '<Resource Group Name>' `
    -TemplateFile 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/scalingAutomation/scalingLogicApp.json' `
    -AutomationConnectionName 'Automation Run As Account Name' ` 
    -AutomationAccountName '<Automation Account Name>' `
    -AutomationAccountResourceGroupName '<Automation Account Resource Group Name>' `
    -BeginPeakTime '<Start of Peak Usage>' `
    -ClassicBrokerUrl '<Broker URL for Classic WVD>' `
    -ClassicTenantGroupName '<Tenant Group Name for Classic WVD>' `
    -ClassicTenantName '<Tenant Name for Classic WVD>' `
    -EndPeakTime '<End of Peak Usage>' `
    -HostPoolName '<Host Pool Name>' `
    -HostPoolResourceGroupName '<Host Pool Resource Group Name>' `
    -LimitSecondsToForceLogOffUser '<Number of seconds>' `
    -LogAnalyticsWorkspaceId '<Workspace ID>' `
    -LogAnalyticsPrimaryKey '<Workspace Key>' `
    -LogicAppName '<Name for the new or existing Logic App>' `
    -LogOffTitle '<Notification Title for log off>' `
    -LogOffMessage '<Notification Message for log off>' `
    -MaintenanceTagName '<Tag name>' `
    -MinimumNumberOfRdsh '<Number of Session Hosts>' `
    -RecurrenceInterval '<Number of minutes for Logic App recurrence>' `
    -SessionThresholdPerCPU '<Number of sessions>' `
    -TimeDifference '<Time zone offset>' `
    -Version '<ARM or Classic>' `
    -Verbose
````

### Try with CLI

````cli
az deployment group create \
    --resource-group '<Resource Group Name>' \
    --template-uri 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/scalingAutomation/scalingLogicApp.json' \
    --parameters \
        AutomationConnectionName='Automation Run As Account Name' \
        AutomationAccountName='<Automation Account Name>' \
        AutomationAccountResourceGroupName='<Automation Account Resource Group Name>' \
        BeginPeakTime='<Start of Peak Usage>' \
        ClassicBrokerUrl='<Broker URL for Classic WVD>' \
        ClassicTenantGroupName='<Tenant Group Name for Classic WVD>' \
        ClassicTenantName='<Tenant Name for Classic WVD>' \
        EndPeakTime='<End of Peak Usage>' \
        HostPoolName='<Host Pool Name>' \
        HostPoolResourceGroupName='<Host Pool Resource Group Name>' \
        LimitSecondsToForceLogOffUser='<Number of seconds>' \
        LogAnalyticsWorkspaceId='<Workspace ID>' \
        LogAnalyticsPrimaryKey='<Workspace Key>' \
        LogicAppName='<Name for the new or existing Logic App>' \
        LogOffTitle='<Notification Title for log off>' \
        LogOffMessage='<Notification Message for log off>' \
        MaintenanceTagName='<Tag name>' \
        MinimumNumberOfRdsh='<Number of Session Hosts>' \
        RecurrenceInterval='<Number of minutes for Logic App recurrence>' \
        SessionThresholdPerCPU='<Number of sessions>' \
        TimeDifference='<Time zone offset>' \
        Version='<ARM or Classic>'
````
