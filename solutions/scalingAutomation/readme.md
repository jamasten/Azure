# Azure Virtual Desktop - Scaling Automation solution

## Description

This solution is a modernized version of the tool provided in the [AVD documentation](https://docs.microsoft.com/en-us/azure/virtual-desktop/set-up-scaling-script). The whole solution is contained in one deployment.  The Automation Account uses a System Assigned Identity with Contributor rights on the AVD resources groups, reducing the permissions the "RunAs" account used with the old tool. The following resources are deployed with this solution:

* Automation Account
  * Runbook
  * Webhook
  * Variable
  * Diagnostic Settings (Optional)
* Logic App
* Role Assignments

By specifying a value for "LogAnalyticsWorkspaceResourceId" parameter, the Runbook job logs and stream will be sent to a Log Analytics Workspace.  Review this Docs page, "[View Automation logs in Azure Monitor logs](https://docs.microsoft.com/en-us/azure/automation/automation-manage-send-joblogs-log-analytics#view-automation-logs-in-azure-monitor-logs)", for the KQL queries to view the log data and create alerts.

## Prerequisites

Ensure the principal deploying this solution has Owner rights on the Azure subscription.

## Template Parameters

### REQUIRED

* **AutomationAccountName**: Name for a new or existing Automation Account
* **BeginPeakTime**: Time when session hosts will scale up and continue to stay on to support peak demand; Format 24 hours, e.g. 9:00 for 9am
* **EndPeakTime**: Time when session hosts will scale down and stay off to support low demand; Format 24 hours, e.g. 17:00 for 5pm
* **HostPoolName**: Name of the AVD host pool to target for scaling
* **HostPoolResourceGroupName**: Name of the resource group for the AVD host pool to target for scaling
* **HostsResourceGroupName**: Name of the resource group for the AVD session hosts
* **LimitSecondsToForceLogOffUser**: The number of seconds to wait before automatically signing out users. If set to 0, any session host that has user sessions will be left untouched
* **LogicAppName**: Name for the new or existing Logic App
* **MinimumNumberOfRdsh**: The minimum number of session host VMs to keep running during off-peak hours
* **SessionThresholdPerCPU**: The maximum number of sessions per CPU that will be used as a threshold to determine when new session host VMs need to be started during peak hours
* **TimeDifference**: Time zone off set for host pool location; Format 24 hours, e.g. -4:00 for Eastern Daylight Time

### OPTIONAL

* **LogAnalyticsWorkspaceResourceId**: Resource ID of the Log Analytics Workspace to use for logging the Runbook jobs and job stream in Azure Automation

### DO NOT MODIFY

* **Timestamp**: The "utcNow" function is used to set a unique name and the expiration on the webhook

## Deploy to Azure

### Azure Portal

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2FscalingAutomation%2Fsolution.json)
[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fjamasten%2FAzure%2Fmaster%2Fsolutions%2FscalingAutomation%2Fsolution.json)

### PowerShell

````powershell
New-AzResourceGroupDeployment `
    -ResourceGroupName '<Resource Group Name>' `
    -TemplateFile 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/scalingAutomation/solution.json' `
    -AutomationAccountName '<Automation Account Name>' `
    -BeginPeakTime '<Start of Peak Usage>' `
    -EndPeakTime '<End of Peak Usage>' `
    -HostPoolName '<Host Pool Name>' `
    -HostPoolResourceGroupName '<Host Pool Resource Group Name>' `
    -HostsResourceGroupName '<Hosts Resource Group Name>' `
    -LimitSecondsToForceLogOffUser '<Number of seconds>' `
    -LogAnalyticsWorkspaceResourceId '<Log Analytics Workspace Resource ID>' ` 
    -LogicAppName '<Name for the new or existing Logic App>' `
    -MinimumNumberOfRdsh '<Number of Session Hosts>' `
    -SessionThresholdPerCPU '<Number of sessions>' `
    -TimeDifference '<Time zone offset>' `
    -Verbose
````

### Azure CLI

````cli
az deployment group create \
    --resource-group '<Resource Group Name>' \
    --template-uri 'https://raw.githubusercontent.com/jamasten/Azure/master/solutions/scalingAutomation/solution.json' \
    --parameters \
        AutomationAccountName='<Automation Account Name>' \
        BeginPeakTime='<Start of Peak Usage>' \
        EndPeakTime='<End of Peak Usage>' \
        HostPoolName='<Host Pool Name>' \
        HostPoolResourceGroupName='<Host Pool Resource Group Name>' \
        HostsResourceGroupName='<Hosts Resource Group Name>' \
        LimitSecondsToForceLogOffUser='<Number of seconds>' \
        LogAnalyticsWorkspaceResourceId='<Log Analytics Workspace Resource ID>' \
        LogicAppName='<Name for the new or existing Logic App>' \
        MinimumNumberOfRdsh='<Number of Session Hosts>' \
        RecurrenceInterval='<Number of minutes for Logic App recurrence>' \
        SessionThresholdPerCPU='<Number of sessions>' \
        TimeDifference='<Time zone offset>' \
````
