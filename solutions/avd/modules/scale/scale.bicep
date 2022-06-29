param AutomationAccountName string
param BeginPeakTime string
param EndPeakTime string
param FslogixSolution string
param FslogixStorage string
param HostPoolName string
param HostPoolResourceGroupName string
param LimitSecondsToForceLogOffUser string
param Location string
param LogicAppPrefix string
param MinimumNumberOfRdsh string
@secure()
param SasToken string
param ScriptsUri string
param SessionHostsResourceGroupName string
param SessionThresholdPerCPU string
param StorageAccountPrefix string
param StorageCount int
param StorageIndex int
param StorageResourceGroupName string
param TimeDifference string
@description('ISO 8601 timestamp used to determine the webhook expiration date.  The webhook is hardcoded to expire 5 years after the timestamp.')
param Timestamp string = utcNow('u')


var ManagementResourceGroupName = resourceGroup().name


module scale_HostPool 'scale_HostPool.bicep' = {
  name: 'Scale_HostPool_${Timestamp}'
  scope: resourceGroup(ManagementResourceGroupName)
  params: {
    AutomationAccountName: AutomationAccountName
    BeginPeakTime: BeginPeakTime
    EndPeakTime: EndPeakTime
    HostPoolName: HostPoolName
    HostPoolResourceGroupName: HostPoolResourceGroupName
    LimitSecondsToForceLogOffUser: LimitSecondsToForceLogOffUser
    Location: Location
    LogicAppPrefix: LogicAppPrefix
    ManagementResourceGroupName: ManagementResourceGroupName
    MinimumNumberOfRdsh: MinimumNumberOfRdsh
    SasToken: SasToken
    ScriptsUri: ScriptsUri
    SessionHostsResourceGroupName: SessionHostsResourceGroupName
    SessionThresholdPerCPU: SessionThresholdPerCPU
    TimeDifference: TimeDifference
  }
}

module scale_AzureFilesPremium 'scale_AzureFilesPremium.bicep' = if(contains(FslogixStorage, 'AzureStorageAccount Premium')) {
  name: 'Scale_AzureFilesPremium_${Timestamp}'
  scope: resourceGroup(ManagementResourceGroupName)
  params: {
    AutomationAccountName: AutomationAccountName
    FslogixSolution: FslogixSolution
    FslogixStorage: FslogixStorage
    Location: Location
    LogicAppPrefix: LogicAppPrefix
    SasToken: SasToken
    ScriptsUri: ScriptsUri
    StorageAccountPrefix: StorageAccountPrefix
    StorageCount: StorageCount
    StorageIndex: StorageIndex
    StorageResourceGroupName: StorageResourceGroupName
  }
} 
