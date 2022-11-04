[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory)]
	$WebHookData
)


$Parameters = ConvertFrom-Json -InputObject $WebHookData.RequestBody
$EnvironmentName = $Parameters.PSObject.Properties['EnvironmentName'].Value
$HostPoolName = $Parameters.PSObject.Properties['HostPoolName'].Value
$HostPoolResourceGroupName = $Parameters.PSObject.Properties['HostPoolResourceGroupName'].Value
$SessionHostExpirationInDays = $Parameters.PSObject.Properties['SessionHostExpirationInDays'].Value
$SubscriptionId = $Parameters.PSObject.Properties['SubscriptionId'].Value
$TenantId = $Parameters.PSObject.Properties['TenantId'].Value
$WorkspaceId = $Parameters.PSObject.Properties['WorkspaceId'].Value


$ErrorActionPreference = 'Stop'

try
{
    # Import Modules
    Import-Module -Name 'Az.Accounts','Az.Compute','Az.DesktopVirtualization','Az.Network','Az.OperationalInsights'
    Write-Output "Imported required modules"

    # Connect to Azure using the Managed Identity
    Connect-AzAccount -Environment $EnvironmentName -Subscription $SubscriptionId -Tenant $TenantId -Identity | Out-Null
    Write-Output "Connected to Azure"

    # Get the resource IDs for the AVD session hosts in the target host pool
    $Counter = 0
	$Results = @()
    $SessionHosts = Get-AzWvdSessionHost -ResourceGroupName $HostPoolResourceGroupName  -HostPoolName $HostPoolName
    foreach($SessionHost in $SessionHosts)
    {
        # Get the resource ID of the managed disk used for the operating system on the session host
        $VirtualMachine = Get-AzVM -ResourceId $SessionHost.ResourceId
        $VirtualMachineOSDisk = $VirtualMachine.StorageProfile.OsDisk.ManagedDisk.Id
        
        # Get the creation date / time of the session host disk to determine if the session host has existed during the expriation time frame
        $Disk = Get-AzDisk -ResourceGroupName $VirtualMachineOSDisk.Split('/')[4] -DiskName $VirtualMachineOSDisk.Split('/')[-1]
        $DiskCreationDate = $Disk.TimeCreated
        
        # Get the expiration date by subtracting the expiration in days param from the current date
        $TodaysDate = Get-Date
		$DiskDays = ($TodaysDate - $DiskCreationDate).Days
        if($DiskDays -ge $SessionHostExpirationInDays)
        {
            $Query = "WVDConnections | where State == 'Connected' | where _ResourceId endswith '$HostPoolName' | where SessionHostName == '$($SessionHost.Name)'"
			$Results += (Invoke-AzOperationalInsightsQuery -WorkspaceId $WorkspaceId -Query $Query -Timespan (New-TimeSpan -Days $SessionHostExpirationInDays)).Results
			if($Results.Count -eq 0)
            {
                # Remove the session host from the host pool
                $SessionHost | Remove-AzWvdSessionHost | Out-Null

                # Remove the virtual machine
                $VirtualMachine | Remove-AzVM -Force | Out-Null

                # Delay to ensure NIC and disk can be removed automatically if using the newer VM API
                Start-Sleep -Seconds 60

                # Remove the network interface
                $NetworkInterface = Get-AzNetworkInterface -ResourceGroupName $VirtualMachine.ResourceGroupName -Name $VirtualMachine.NetworkProfile.NetworkInterfaces[0].Id.Split('/')[-1] -ErrorAction 'SilentlyContinue'
                if($NetworkInterface)
                {
                    $NetworkInterface | Remove-AzNetworkInterface -Force | Out-Null
                }

                # Remove the disk
                $Disk = Get-AzDisk -ResourceGroupName $SessionHostDisk.Split('/')[4] -DiskName $SessionHostDisk.Split('/')[-1] -ErrorAction 'SilentlyContinue'
                if($Disk)
                {
                    $Disk | Remove-AzDisk -Force | Out-Null
                }

                $Counter++
                Write-Output "Removed session host: $SessionHostName"
            }
        }
    }
    if($Counter -eq 0)
    {
        Write-Output 'No session hosts were removed'
    }
}
catch 
{
    Write-Output $_.Exception
    throw
}