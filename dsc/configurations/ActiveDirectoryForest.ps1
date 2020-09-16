configuration ActiveDirectoryForest 
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$Domain
    ) 
    
    Import-DscResource -ModuleName ActiveDirectoryDsc -ModuleVersion '4.2.0.0'
    Import-DscResource -ModuleName ComputerManagementDsc -ModuleVersion '8.4.0'
    Import-DscResource -ModuleName NetworkingDsc -ModuleVersion '8.1.0'
    Import-DscResource -ModuleName PSDscResources -ModuleVersion '2.12.0.0'
    Import-DscResource -ModuleName xDnsServer -ModuleVersion '1.16.0.0'

    $DomainCreds = Get-AutomationPSCredential 'Administrator'

    Node localhost
    {
        PendingReboot PreAddsInstall
        {
            Name = 'PreAddsInstall'
            PsDscRunAsCredential = $DomainCreds
            SkipCcmClientSDK = $false
            SkipComponentBasedServicing = $false
            SkipPendingComputerRename = $false
            SkipPendingFileRename = $false
            SkipWindowsUpdate = $false
        }

	    WindowsFeature DNS 
        { 
            Ensure = "Present" 
            Name = "DNS"		
        }

	    WindowsFeature DnsTools
	    {
	        Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
	    }

        DnsServerAddress DnsServerAddress 
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
         
        ADDomain FirstDomainController 
        {
            DomainName = $Domain
            Credential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            ForestMode = 'WinThreshold'
	  	    DependsOn = "[WindowsFeature]ADDSInstall"
        }

        xDnsServerDiagnostics EnableDnsDiagnostics
        {
            Name = 'EnableDnsDiagnostics'
            Answers = $true
            EnableLogFileRollover = $true
            FullPackets = $true
            EnableLoggingForLocalLookupEvent = $true
            EnableLoggingForPluginDllEvent = $true
            EnableLoggingForRecursiveLookupEvent = $true
            EnableLoggingForRemoteServerEvent = $true
            EnableLoggingForServerStartStopEvent = $true
            EnableLoggingForTombstoneEvent = $true
            EnableLoggingForZoneDataWriteEvent = $true
            EnableLoggingForZoneLoadingEvent = $true
            Notifications = $true
            Queries = $true
            QuestionTransactions = $true
            SaveLogsToPersistentStorage = $true
            ReceivePackets = $true
            SendPackets = $true
            TcpPackets = $true
            UdpPackets = $true
            UnmatchedResponse = $true
            Update = $true
            WriteThrough = $true
        }

        xDnsServerForwarder Azure
        {
            IsSingleInstance = 'Yes'
            IPAddresses = '168.63.129.16'
            UseRootHint = $true
            DependsOn = "[WindowsFeature]DNS"
        }
    }
}