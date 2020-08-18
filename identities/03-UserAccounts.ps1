# Create User Accounts
$Users = @(
    @{
        "FirstName" = "Cereal";
        "LastName" = "Killer";
    },
    @{
        "FirstName" = "Lord";
        "LastName" = "Nikon";
    },
    @{
        "FirstName" = "Crash";
        "LastName" = "Override";
    },
    @{
        "FirstName" = "Phantom";
        "LastName" = "Phreak";
    },
    @{
        "FirstName" = "Acid";
        "LastName" = "Burn";
    },
    @{
        "FirstName" = "Zero";
        "LastName" = "Cool";
    },
    @{
        "FirstName" = "The";
        "LastName" = "Plague";
    }
)
$Password = Read-Host -Prompt 'Enter User Account Passwords' -AsSecureString

foreach($User in $Users)
{
    $Name = $User.FirstName + ' ' + $User.LastName
    $UPN = ($User.FirstName + $User.LastName + '@jasonmasten.com').ToLower()

    New-ADUser `
        -AccountPassword $Password `
        -CannotChangePassword $True `
        -ChangePasswordAtLogon $False `
        -DisplayName $Name `
        -Enabled $True `
        -GivenName $User.FirstName `
        -Name $Name `
        -PasswordNeverExpires $True `
        -Surname $User.LastName `
        -UserPrincipalName $UPN
}