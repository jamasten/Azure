[Cmdletbinding()]
param(
    [parameter(Mandatory)]
    [ValidateSet('AvailabilitySet','AvailabilityZones','None')]
    [string]$Availability, 

    [parameter(Mandatory=$false)]
    [string]$AvailabilitySetNamePrefix,

    [parameter(Mandatory=$false)]
    [ValidateSet('1', '2', '3')]
    [array]$AvailabilityZones = @('1'), 

    [parameter(Mandatory)]
    [ValidateSet('ActiveDirectory','None','NoneWithIntune')]
    [string]$DomainServices,

    [parameter(Mandatory)]
    [ValidateSet('AzureCloud','AzureUSGovernment', 'AzureChinaCloud', 'AzureGermanCloud')]
    [string]$Environment,

    [parameter(Mandatory)]
    [string]$HostPoolName,

    [parameter(Mandatory)]
    [string]$HostPoolResourceGroupName,

    [parameter(Mandatory)]
    [string]$KeyVaultResourceId,

    [parameter(Mandatory)]
    [string]$SessionHostOuPath,

    [parameter(Mandatory)]
    [string]$SubnetResourceId,

    [parameter(Mandatory)]
    [string]$TemplateSpecName,

    [parameter(Mandatory)]
    [string]$TemplateSpecVersion,

    [parameter(Mandatory)]
    [string]$TenantId,

    [parameter(Mandatory)]
    [string]$VirtualMachineResourceGroupName
)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

$SubscriptionId = $SubnetResourceId.Split('/')[2]
$VirtualMachineLocation = (Get-AzVirtualNetwork -ResourceGroupName $SubnetResourceId.Split('/')[4] -Name $SubnetResourceId.Split('/')[8]).Location

try
{
    # Set Context to Subscription for AVD deployment
    $SubscriptionName = (Connect-AzAccount -Environment $Environment -Subscription $SubscriptionId -Tenant $TenantId).Context.Subscription.Name
    Write-Host 'Connected to Azure.'

    $Location = (Get-AzWvdHostPool -Name $HostPoolName -ResourceGroupName $HostPoolResourceGroupName).Location

    # Update default values for params in JSON template
    $TemplateJson = Get-Content -Path .\solution.json
    $Template = $TemplateJson | ConvertFrom-Json
    $Template.parameters.Availability.defaultValue = $Availability
    $Template.parameters.AvailabilitySetNamePrefix.defaultValue = if($AvailabilitySetNamePrefix){$AvailabilitySetNamePrefix}else{''}
    $Template.parameters.AvailabilityZones.defaultValue = $AvailabilityZones
    $Template.parameters.DomainServices.defaultValue = $DomainServices
    $Template.parameters.HostPoolName.defaultValue = $HostPoolName
    $Template.parameters.HostPoolResourceGroupName.defaultValue = $HostPoolResourceGroupName
    $Template.parameters.KeyVaultResourceId.defaultValue = $KeyVaultResourceId
    $Template.parameters.SessionHostOuPath.defaultValue = $SessionHostOuPath
    $Template.parameters.SubnetResourceId.defaultValue = $SubnetResourceId
    $Template.parameters.VirtualMachineLocation.defaultValue = $VirtualMachineLocation
    $Template.parameters.VirtualMachineResourceGroupName.defaultValue = $VirtualMachineResourceGroupName
    $UpdatedTemplateJson = $Template | ConvertTo-Json -Depth 100
    Write-Host 'Captured the template file and updated the default values.'

    # Update property values in UI Definition
    $UiDefinitionJson = Get-Content -Path .\uiDefinition.json
    $UiDefinition = $UiDefinitionJson | ConvertFrom-Json
    $UiDefinition.view.properties.title = "Add Session Hosts to $($HostPoolName)"
    $UiDefinition.view.properties.steps.elements[0].location.allowedValues = @("$Location")
    $Constraint = "[equals(steps('basics').resourceScope.subscription.displayName, '$($SubscriptionName)')]"
    $UiDefinition.view.properties.steps.elements[0].subscription.constraints.validations[0].isValid = $Constraint
    $Message = "Only the following subscription is allowed: $($SubscriptionName)"
    $UiDefinition.view.properties.steps.elements[0].subscription.constraints.validations[0].message = $Message
    $UpdatedUiDefinitionJson = $UiDefinition | ConvertTo-Json -Depth 100
    Write-Host 'Captured the UI Definition file and updated the property values.'

    # Create a template spec with a custom UI definition in the host pool resource group
    New-AzTemplateSpec `
        -Location $Location `
        -ResourceGroupName $HostPoolResourceGroupName `
        -Name $TemplateSpecName `
        -Version $TemplateSpecVersion `
        -TemplateJson $UpdatedTemplateJson `
        -UIFormDefinitionString $UpdatedUiDefinitionJson `
        -Force | Out-Null
    Write-Host "Created or updated the template spec in the following resource group: $HostPoolResourceGroupName."
}
catch
{
    $_ | Select-Object *
}