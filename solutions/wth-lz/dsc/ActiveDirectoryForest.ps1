configuration ActiveDirectoryForest 
{ 
   param 
   ( 
        [Parameter(Mandatory=$true)]
        [String]$Domain,

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$DomainCreds
    ) 
    
    Import-DscResource -ModuleName ActiveDirectoryDsc -ModuleVersion '4.2.0.0'
    Import-DscResource -ModuleName PSDscResources -ModuleVersion '2.12.0.0'
    Import-DscResource -ModuleName xDnsServer -ModuleVersion '1.16.0.0'

    $Users = @(
        @{
            "FirstName" = "Adam";
            "LastName" = "Warlock";
        },
        @{
            "FirstName" = "Batman";
            "LastName" = "";
        },
        @{
            "FirstName" = "Black";
            "LastName" = "Adam";
        },
        @{
            "FirstName" = "Black";
            "LastName" = "Widow";
        },
        @{
            "FirstName" = "Captain";
            "LastName" = "America";
        },
        @{
            "FirstName" = "Cat";
            "LastName" = "Woman";
        },
        @{
            "FirstName" = "Dr";
            "LastName" = "Strange";
        },
        @{
            "FirstName" = "Gamora";
            "LastName" = "";
        },
        @{
            "FirstName" = "Hulk";
            "LastName" = "";
        },
        @{
            "FirstName" = "Joker";
            "LastName" = "";
        },
        @{
            "FirstName" = "Lex";
            "LastName" = "Luthor";
        },
        @{
            "FirstName" = "Maria";
            "LastName" = "Hill";
        },
        @{
            "FirstName" = "Nick";
            "LastName" = "Fury";
        },
        @{
            "FirstName" = "Night";
            "LastName" = "Thrasher";
        },
        @{
            "FirstName" = "Nova";
            "LastName" = "";
        },
        @{
            "FirstName" = "Robin";
            "LastName" = "";
        },
        @{
            "FirstName" = "Rocket";
            "LastName" = "";
        },
        @{
            "FirstName" = "Shazam";
            "LastName" = "";
        },
        @{
            "FirstName" = "Speed";
            "LastName" = "Ball";
        },
        @{
            "FirstName" = "Spiderman";
            "LastName" = "";
        },
        @{
            "FirstName" = "Star";
            "LastName" = "Lord";
        },
        @{
            "FirstName" = "Dr";
            "LastName" = "Strange";
        },
        @{
            "FirstName" = "Superman";
            "LastName" = "";
        },
        @{
            "FirstName" = "Thor";
            "LastName" = "";
        },
        @{
            "FirstName" = "Wonder";
            "LastName" = "Woman";
        }
    )

    Node localhost
    {
       LocalConfigurationManager            
       {            
          ActionAfterReboot = 'ContinueConfiguration'            
          ConfigurationMode = 'ApplyOnly'            
          RebootNodeIfNeeded = $true            
       }
        
        WindowsFeature ADDSInstall 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services" 
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

        WindowsFeature DnsTools
	    {
	        Ensure = "Present"
            Name = "RSAT-DNS-Server"
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

        xDnsServerForwarder Azure
        {
            IsSingleInstance = 'Yes'
            IPAddresses = '168.63.129.16'
            UseRootHint = $true
            DependsOn = "[ADDomain]FirstDomainController"
        }

        foreach($User in $Users)
        {
            ADUser $($User.FirstName + $User.LastName)
            {
                Ensure = 'Present'
                Password = $DomainCreds
                PasswordNeverResets = $false
                DomainName = $Domain
                CannotChangePassword = $true
                ChangePasswordAtLogon = $false 
                DisplayName = $User.FirstName + ' ' + $User.LastName
                Enabled = $true
                GivenName = $User.FirstName
                PasswordNeverExpires = $true
                Surname = $User.LastName
                UserName = ($User.FirstName + $User.LastName).ToLower()
                UserPrincipalName = ($User.FirstName + $User.LastName + '@' + $Domain).ToLower()
                DependsOn = "[ADDomain]FirstDomainController"
            }
        }
    }
}
