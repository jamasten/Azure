$Users = Get-MsolUser
$Data = foreach($User in $Users)
{
    [pscustomobject][ordered]@{
        FirstName = $User.FirstName
        LastName = $User.LastName
        DisplayName = $User.DisplayName
        UPN = $User.UserPrincipalName
    }
}

$Data | Export-Csv -NoTypeInformation -Path "$HOME\Desktop\AzureAdUsers.csv"