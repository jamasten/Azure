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
$Users = Get-AzADUser | Where-Object {$_.UserPrincipalName -like "jamasten*" -or $_.UserPrincipalName -like "admin*"}
foreach($User in $Users)
{
  if($null -eq (Get-AzADGroupMember -GroupDisplayName $AdminGroupName | Where-Object {$_.UserPrincipalName -eq $User.UserPrincipalName}))
  {
    Add-AzADGroupMember `
      -TargetGroupDisplayName $AdminGroupName `
      -MemberUserPrincipalName $User.UserPrincipalName
  }
}