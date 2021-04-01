param 
( 
    [Parameter(Mandatory)]
    [String]$Environment,

    [Parameter(Mandatory)]
    [String]$KerberosEncryptionType,

    [Parameter(Mandatory)]
    [String]$Key,

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

$Password = ConvertTo-SecureString -String $Key -AsPlainText -Force

$SPN = 'cifs/' + $StorageAccountName + $Suffix

$Test = (Get-ADComputer -Identity $StorageAccountName).SID.Value
if(!$Test)
{
    if(!$OuPath)
    {
        New-ADComputer `
            -Name $StorageAccountName `
            -ServicePrincipalNames $SPN `
            -AccountPassword $Password `
            -KerberosEncryptionType $KerberosEncryptionType
    } 
    else 
    {
        New-ADComputer `
            -Name $StorageAccountName `
            -ServicePrincipalNames $SPN `
            -AccountPassword $Password `
            -KerberosEncryptionType $KerberosEncryptionType `
            -Path $OuPath
    }
}

$Domain = Get-ADDomain
$ComputerSid = (Get-ADComputer -Identity $StorageAccountName).SID.Value

Write-Host ",$($Domain.ObjectGUID),$($Domain.DomainSID),$($ComputerSid),"