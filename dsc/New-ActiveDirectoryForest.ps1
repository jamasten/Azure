configuration ActiveDirectoryForest 
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName
    ) 
    
    Import-DscResource -ModuleName xActiveDirectory -ModuleVersion '3.0.0.0'
    Import-DscResource -ModuleName xNetworking -ModuleVersion '5.7.0.0'
    Import-DscResource -ModuleName xPendingReboot -ModuleVersion '0.4.0.0'
    Import-DscResource -ModuleName PSDscResources -ModuleVersion '2.9.0.0'

    $DomainCreds = Get-AutomationPSCredential 'Administrator'

    Node localhost
    {
        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }

	    WindowsFeature DNS 
        { 
            Ensure = "Present" 
            Name = "DNS"		
        }

        Script EnableDNSDiags
        {
      	    SetScript = { 
		        Set-DnsServerDiagnostics -All $true
            }
            GetScript =  { @{ Result = Get-DnsServerDiagnostics} }
            TestScript = { 
                $DnsSettings = Get-DnsServerDiagnostics
                $Values = @()
                $Values += $DnsSettings.SaveLogsToPersistentStorage
                $Values += $DnsSettings.Queries
                $Values += $DnsSettings.Answers
                $Values += $DnsSettings.Notifications
                $Values += $DnsSettings.Update
                $Values += $DnsSettings.QuestionTransactions
                $Values += $DnsSettings.UnmatchedResponse
                $Values += $DnsSettings.SendPackets
                $Values += $DnsSettings.ReceivePackets
                $Values += $DnsSettings.TcpPackets
                $Values += $DnsSettings.UdpPackets
                $Values += $DnsSettings.FullPackets
                $Values += $DnsSettings.EnableLogFileRollover
                $Values += $DnsSettings.WriteThrough
                $Values += $DnsSettings.EnableLoggingForLocalLookupEvent
                $Values += $DnsSettings.EnableLoggingForPluginDllEvent
                $Values += $DnsSettings.EnableLoggingForRecursiveLookupEvent
                $Values += $DnsSettings.EnableLoggingForRemoteServerEvent
                $Values += $DnsSettings.EnableLoggingForServerStartStopEvent
                $Values += $DnsSettings.EnableLoggingForTombstoneEvent
                $Values += $DnsSettings.EnableLoggingForZoneDataWriteEvent
                $Values += $DnsSettings.EnableLoggingForZoneLoadingEvent

                if($Values -contains $false)
                {
                    $false
                }
                else
                {
                    $true
                }
            }
	        DependsOn = "[WindowsFeature]DNS"
        }

	    WindowsFeature DnsTools
	    {
	        Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
	    }

        xDnsServerAddress DnsServerAddress 
        { 
            Address        = '127.0.0.1' 
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
	        DependsOn = "[WindowsFeature]DNS"
        }

        WindowsFeature ADDSInstall 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services"
	        DependsOn="[WindowsFeature]DNS" 
        } 

        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter
        {
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }
         
        xADDomain FirstDomainController 
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "C:\NTDS"
            LogPath = "C:\NTDS"
            SysvolPath = "C:\SYSVOL"
	  	    DependsOn = "[WindowsFeature]ADDSInstall"
        }
    }
}