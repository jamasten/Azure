param 
( 
    [Parameter(Mandatory)]
    [String]$Environment,

    [Parameter(Mandatory)]
    [String]$KerberosEncryptionType,

    [Parameter(Mandatory)]
    [SecureString]$Key,

    [Parameter(Mandatory=$false)]
    [String]$OuPath,

    [Parameter(Mandatory)]
    [String]$StorageAccountName
)

$Suffix = switch($Environment)
{
    AzureCloud {'.file.core.windows.net'}
    AzureUSGovernment {'.file.core.usgovcloudapi.net'}
}

$SPN = 'cifs/' + $StorageAccountName + $Suffix

if(!$OuPath)
{
    New-ADComputer `
        -Name $StorageAccountName `
        -ServicePrincipalNames $SPN `
        -AccountPassword $Key `
        -KerberosEncryptionType $KerberosEncryptionType

} else {

    New-ADComputer `
        -Name $StorageAccountName `
        -ServicePrincipalNames $SPN `
        -AccountPassword $Key `
        -KerberosEncryptionType $KerberosEncryptionType `
        -Path $OuPath

}

$Domain = Get-ADDomain
$ComputerSid = (Get-ADComputer -Identity $StorageAccountName).SID.Value

Write-Host "$($Domain.ObjectGUID),$($Domain.DomainSID),$($ComputerSid)"