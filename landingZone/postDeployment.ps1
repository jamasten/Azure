$UserPrincipalName = Read-Host -Prompt 'Input UPN to add to AAD DC Administrators group'
$AdminGroupName = 'AAD DC Administrators'

# Create Security Group for Azure ADDS administration in Azure AD
if($null -eq (Get-AzADGroup -DisplayName $AdminGroupName))
{
  New-AzADGroup `
    -DisplayName $AdminGroupName `
    -MailNickname $($AdminGroupName -replace '[\W]','')
}

# Add Azure ADDS Admin Account to Security Group in Azure AD
Start-Sleep 10
$User = Get-AzADUser | Where-Object {$_.UserPrincipalName -eq $UserPrincipalName}
if($null -eq (Get-AzADGroupMember -GroupDisplayName $AdminGroupName | Where-Object {$_.UserPrincipalName -eq $User.UserPrincipalName}))
{
  Add-AzADGroupMember `
    -TargetGroupDisplayName $AdminGroupName `
    -MemberUserPrincipalName $User.UserPrincipalName
}