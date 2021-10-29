# Bing Maps API Key
$Key = ''

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

$URI = "https://management.azure.com/subscriptions/$subscriptionId/locations?api-version=2020-01-01"
#$URI = "https://management.usgovcloudapi.net/subscriptions/$subscriptionId/locations?api-version=2020-01-01"

$Locations = (Invoke-RestMethod `
    -Headers $Header `
    -Method Get `
    -Uri $URI `
    -Verbose).value

$Data = @()
foreach($Location in $Locations)
{
    if($Location -notlike "*(Stage)")
    {
        $Uri = "https://dev.virtualearth.net/REST/v1/TimeZone/$($Location.metadata.latitude),$($Location.metadata.longitude)?&key=$Key"
        if($Location.metadata.latitude)
        {
            $TimeZone = (Invoke-RestMethod -Method Get -Uri $Uri).resourceSets.resources.timeZone.abbreviation
        }
        else
        {
            $TimeZone = ''
        }
        $Data += [pscustomobject][ordered]@{
            Name = $Location.displayName
            TimeZone = $TimeZone
        }
        Start-Sleep 1
    }
}

$Data | Sort-Object Name