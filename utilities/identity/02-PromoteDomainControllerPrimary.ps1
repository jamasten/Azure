# Promote Primary Domain Controller
Import-Module ADDSDeployment

Install-ADDSForest `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\windows\NTDS" `
    -DomainMode "WinThreshold" `
    -DomainName "jasonmasten.com" `
    -DomainNetbiosName "JASONMASTEN" `
    -ForestMode "WinThreshold" `
    -InstallDns:$true `
    -LogPath "C:\windows\NTDS" `
    -NoRebootOnCompletion:$false `
    -SysvolPath "C:\windows\SYSVOL" `
    -Force:$true