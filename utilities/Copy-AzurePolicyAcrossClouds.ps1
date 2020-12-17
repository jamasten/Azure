Param(
    [parameter(Mandatory=$true)]
    [ValidateSet("AzureCloud","AzureUSGovernment")]
    [string]$DestinationCloud,

    [parameter(Mandatory=$true)]
    [string]$DestinationSubscriptionId,

    [parameter(Mandatory=$true)]
    [string]$IntiativeName,

    [parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [string]$Path,

    [parameter(Mandatory=$true)]
    [ValidateSet("AzureCloud","AzureUSGovernment")]
    [string]$SourceCloud,

    [parameter(Mandatory=$true)]
    [string]$SourceSubscriptionId
)

# Disconnect any previously connected Azure subscriptions
Disconnect-AzAccount

# Connect to the source cloud subscription
Connect-AzAccount -Environment $SourceCloud

# Set source Azure Subscription Context
Set-AzContext -Subscription $SourceSubscriptionId

# Get the initiative's properties using the name
$Initiative = Get-AzPolicySetDefinition | Where-Object {$_.Properties.DisplayName -eq $IntiativeName}

# Download Azure policies to file system
New-Item -Path $($Path + '\' + $IntiativeName) -ItemType Directory
foreach($Policy in $Initiative.Properties.PolicyDefinitions)
{
    $Name = $Policy.policyDefinitionId.Split('/')[-1]
    $NewPolicy = $([System.Text.RegularExpressions.Regex]::Unescape($(Get-AzPolicyDefinition -Name $Name | ConvertTo-Json -Depth 100)))
    $NewPolicy | Out-File -FilePath $($Path + '\' + $IntiativeName + '\' + $Name + '.json')
}

# Disconnect the source Azure subscription
Disconnect-AzAccount

# Connect to the destination cloud subscription
Connect-AzAccount -Environment $DestinationCloud

# Set destination Azure Subscription Context
Set-AzContext -Subscription $DestinationSubscriptionId

# Create policy definitons in destination cloud subscription
$Files = Get-ChildItem -Path $($Path + '\' + $IntiativeName)
foreach($File in $Files)
{
    $Content = Get-Content -Path $File.FullName | ConvertFrom-Json
    $Description = $Content.Properties.Description
    $DisplayName = $Content.Properties.DisplayName
    # Metadata is disabled since this currently (11/2/2020) creates static policy definitions that can't be managed in the portal
    #$Metadata = $Content.Properties.Metadata | ConvertTo-Json -Depth 100
    $Parameters = $Content.Properties.Parameters | ConvertTo-Json -Depth 100
    $PolicyRule = $([System.Text.RegularExpressions.Regex]::Unescape($($Content.Properties.PolicyRule | ConvertTo-Json -Depth 100)))
    if($Parameters)
    {
        $Output = New-AzPolicyDefinition -Name $File.Name.Split('.')[0] -Policy $PolicyRule -Parameter $Parameters -DisplayName $DisplayName -Description $Description -ErrorAction Stop
    }
    else
    {
        $Output = New-AzPolicyDefinition -Name $File.Name.Split('.')[0] -Policy $PolicyRule -DisplayName $DisplayName -Description $Description -ErrorAction Stop
    }
}

# Get the destination cloud subscription ID
$Id = (Get-AzContext).Subscription.Id 

# Create a custom initiative in the destination cloud subscription
New-AzPolicySetDefinition `
    -Name 'NIST Test' `
    -DisplayName 'NIST Test' `
    -Description $Initiative.Properties.Description `
    -PolicyDefinition $([System.Text.RegularExpressions.Regex]::Unescape($($Initiative.Properties.PolicyDefinitions | ConvertTo-Json -Depth 100))) `
    -Metadata $($Initiative.Properties.Metadata | ConvertTo-Json  -Depth 100)  `
    -Parameter $($Initiative.Properties.Parameters | ConvertTo-Json  -Depth 100)  `
    -SubscriptionId $Id `
    -GroupDefinition $($Initiative.Properties.PolicyDefinitionGroups | ConvertTo-Json  -Depth 100)