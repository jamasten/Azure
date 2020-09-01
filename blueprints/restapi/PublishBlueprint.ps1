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

$URI = 'https://management.azure.com/providers/Microsoft.Management/managementGroups/IT/providers/Microsoft.Blueprint/blueprints/MyBlueprint/versions/1-0?api-version=2018-11-01-preview'

Invoke-RestMethod `
    -Headers $Header `
    -Method Put `
    -Uri $URI `
    -Verbose