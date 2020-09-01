# Create a custom Azure Policy Initiative Definition using a Built-In Initiative Definition

Use the code below to copy an Azure Policy built-in initiative and convert it to a custom initiative.  This example is scoped at a subscription and also provides the Group Definition information used in the Regulatory Compliance initiatives.  The "ManageGroupName" parameter can be used in place of the "SubscriptionId" parameter to scope the definition to a management group.  The "GroupDefiniton" parameter should be removed if you are copying an initiative that is not in the Regulatory Compliance category.

## Try with PowerShell

````powershell

# Get subscription ID
$Id = (Get-AzContext).Subscription.Id 

# Get the built-in initiative names and copy the value of the desired initiative
(Get-AzPolicySetDefinition).Properties.DisplayName | Sort-Object

# Get the initiative's properties using the name
$Name = '<Input name of the initiative>'
$Initiative = Get-AzPolicySetDefinition | Where-Object {$_.Properties.DisplayName -eq $Name}

# Create a custom initiative
New-AzPolicySetDefinition `
    -Name '<Input custom initiative name>' `
    -DisplayName '<Input custom initiative name>' `
    -Description $Initiative.Properties.Description `
    -PolicyDefinition $([System.Text.RegularExpressions.Regex]::Unescape($($Initiative.Properties.PolicyDefinitions | ConvertTo-Json -Depth 100))) `
    -Metadata $($Initiative.Properties.Metadata | ConvertTo-Json  -Depth 100)  `
    -Parameter $($Initiative.Properties.Parameters | ConvertTo-Json  -Depth 100)  `
    -SubscriptionId $Id `
    -GroupDefinition $($Initiative.Properties.PolicyDefinitionGroups | ConvertTo-Json  -Depth 100)

````
