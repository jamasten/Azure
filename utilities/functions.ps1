function Get-PublicIpAddress
{
    $url = "http://checkip.dyndns.com"   
    $webclient = New-Object System.Net.WebClient  
    $response = $webclient.DownloadString($url).Trim()
    $ip = (Select-String -InputObject $response -Pattern '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').Matches.Value
    $ip
}