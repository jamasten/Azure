Param(

    [parameter(Mandatory)]
    [string]$CertificateDnsName,

    [parameter(Mandatory)]
    [securestring]$CertificatePassword,

    [parameter(Mandatory)]
    [string]$CertificateSubject

)

$Certificate = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName $CertificateDnsName -Type CodeSigningCert -Subject $CertificateSubject
$CertificatePath = "Cert:\LocalMachine\My\$($Certificate.Thumbprint)"
Export-PfxCertificate -Cert $CertificatePath -FilePath "$HOME\Downloads\$CertificateSubject.pfx" -Password $CertificatePassword