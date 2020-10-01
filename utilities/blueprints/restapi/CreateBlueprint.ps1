# Log in first with Connect-AzAccount
$azContext = Get-AzContext
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$Header = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.AccessToken
}
$subscriptionId = $azContext.Subscription.Id

$URI = 'https://management.azure.com/providers/Microsoft.Management/managementGroups/IT/providers/Microsoft.Blueprint/blueprints/MyBlueprint?api-version=2018-11-01-preview'

$Body = @'
{
    "properties": {
        "description": "This blueprint sets tag policy and role assignment on the subscription, creates a ResourceGroup, and deploys a resource template and role assignment to that ResourceGroup.",
        "targetScope": "subscription",
        "resourceGroups": {
            "storageRG": {
                "description": "Contains the resource template deployment and a role assignment."
            }
        }
    }
}
'@

Invoke-RestMethod `
    -Headers $Header `
    -Method Put `
    -Uri $URI `
    -Body $Body `
    -Verbose