Get-DscConfigurationStatus

. .\reboot.ps1
Reboot

Start-DscConfiguration -Path C:\Users\rebukem\Desktop\Reboot -Verbose -Wait