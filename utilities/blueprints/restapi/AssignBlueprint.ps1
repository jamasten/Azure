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


$URI = 'https://management.azure.com/providers/Microsoft.Management/managementGroups/IT/providers/Microsoft.Blueprint/blueprintAssignments/assignMyBlueprint?api-version=2018-11-01-preview'


$Body = @'
{
    "identity": {
        "type": "UserAssigned",
        "userAssignedIdentities": {
            "/subscriptions/5edfe207-eefc-428f-b5fb-1c24bb7ff301/resourceGroups/DefaultResourceGroup-EUS/providers/Microsoft.ManagedIdentity/userAssignedIdentities/blueprints": {}
        }
    },
    "properties": {
        "blueprintId": "/providers/Microsoft.Management/managementGroups/IT/providers/Microsoft.Blueprint/blueprints/MyBlueprint",
        "resourceGroups": {
            "storageRG": {
                "name": "StorageAccount",
                "location": "eastus2"
            }
        },
        "scope": "/subscriptions/5edfe207-eefc-428f-b5fb-1c24bb7ff301",
        "locks": {
            "mode": "AllResourcesDoNotDelete"
        },
        "parameters": {
        }
    },
    "location": "eastus"
}
'@

$Body = @'
{
    "identity": {
        "type": "SystemAssigned"
    },
    "properties": {
        "blueprintId": "/providers/Microsoft.Management/managementGroups/IT/providers/Microsoft.Blueprint/blueprints/MyBlueprint",
        "resourceGroups": {
            "storageRG": {
                "name": "StorageAccount",
                "location": "eastus2"
            }
        },
        "scope": "/subscriptions/5edfe207-eefc-428f-b5fb-1c24bb7ff301",
        "locks": {
            "mode": "AllResourcesDoNotDelete"
        },
        "parameters": {
        }
    },
    "location": "eastus"
}
'@

Invoke-RestMethod `
    -Headers $Header `
    -Method Put `
    -Uri $URI `
    -Body $Body `
    -Verbose