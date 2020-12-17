$KeyVault = '' # Name of the Azure KeyVault
$UserSecretName = '' # Name of the Username secret in Azure KeyVault
$PasswordSecretName = '' # Name of the Password secret in Azure KeyVault

$UsernameSecret = Get-AzKeyVaultSecret -VaultName $KeyVault -Name $UserSecretName
$ssPtr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($UsernameSecret.SecretValue)
try
{
   $secretValueText = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ssPtr)
} 
finally 
{
   [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ssPtr)
}
$Username = $secretValueText
$Password = (Get-AzKeyVaultSecret -VaultName $KeyVault -Name $PasswordSecretName).SecretValue
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $Password