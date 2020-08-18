#Create new user in Azure AD
$Password = Read-Host -Prompt 'Enter User Account Passwords' -AsSecureString

New-AzADUser `
    -DisplayName 'AD Connect' `
    -UserPrincipalName 'adconnect@jasonmasten.com' `
    -Password $Password `
    -MailNickname 'ADConnect'

#Assign Global Admin permissions
$User = Get-AzureADUser -Filter "userPrincipalName eq 'adconnect@jasonmasten.com'"

New-AzureADMSRoleAssignment `
    -ResourceScope '/' `
    -RoleDefinitionId '62e90394-69f5-4237-9190-012177145e10' `
    -PrincipalId $User.objectId