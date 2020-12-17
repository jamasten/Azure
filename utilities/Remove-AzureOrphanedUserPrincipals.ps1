$Users = @(
    'acidburn@jasonmasten.com',
    'adconnect@jasonmasten.com',
    'cerealkiller@jasonmasten.com',
    'crashoverride@jasonmasten.com',
    'lordnikon@jasonmasten.com',
    'phantomphreak@jasonmasten.com',
    'theplague@jasonmasten.com',
    'zerocool@jasonmasten.com'
)
$Users += Get-AzADUser | Where-Object {$_.UserPrincipalName -like "Sync_*"} | Select-Object -ExpandProperty UserPrincipalName

foreach($User in $Users)
{
    Remove-AzADUser -UserPrincipalName $User -Force 
}