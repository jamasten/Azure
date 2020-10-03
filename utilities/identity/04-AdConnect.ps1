#Create new user in Azure AD
$Password = Read-Host -Prompt 'Enter Password for AD Connect account' -AsSecureString

New-AzADUser `
    -DisplayName 'AD Connect' `
    -UserPrincipalName 'adconnect@jasonmasten.com' `
    -Password $Password `
    -MailNickname 'ADConnect'

Connect-AzureAD -TenantId ''

#Assign Global Admin permissions
$User = Get-AzureADUser -Filter "userPrincipalName eq 'adconnect@jasonmasten.com'"

New-AzureADMSRoleAssignment `
    -ResourceScope '/' `
    -RoleDefinitionId '62e90394-69f5-4237-9190-012177145e10' `
    -PrincipalId $User.objectId

$SecureVmPassword = ConvertTo-SecureString -String 'Rightaboutnow@2020' -AsPlainText -Force
$VSE = @{
    Domain = $Domain
}
$VSE.Add("VmPassword", $SecureVmPassword)
New-AzResourceGroupDeployment -ResourceGroupName rg-identity-dev-eastus -TemplateFile 'C:\Users\jamasten\OneDrive - Microsoft\Desktop\userAccountTest.json' -TemplateParameterObject $VSE