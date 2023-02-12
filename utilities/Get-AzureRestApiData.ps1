$azContext = Get-AzContext
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$Header = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.AccessToken
}
$subscriptionId = $azContext.Subscription.Id

$URI = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Storage/resourceTypes?api-version=2021-04-01"

$Data = (Invoke-RestMethod `
    -Headers $Header `
    -Method Get `
    -Uri $URI `
    -Verbose).value