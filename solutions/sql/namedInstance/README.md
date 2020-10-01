# Convert the default SQL instance to a named SQL instance

## Steps
1. Deploy a SQL Server VM from Azure Marketplace
    - Solution: deploy using the portal or template deployment

2. Uninstall the IaaS extension from the Azure portal
    - Solution: use a "deployment script" resource in an ARM template to uninstall the extension
    - References:
        - https://docs.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts
        - https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-tutorial-deployment-script

3. Uninstall SQL Server completely within the SQL Server VM
    - Solution: use the cmdline tool in conjunction with the custom script extension to uninstall
    - References:
        - https://www.sqlservercentral.com/blogs/uninstalling-sql-server-from-the-command-line-to-remove-unwanted-background-instances

4. Install SQL Server with a named instance within the SQL Server VM
    - Solution: use DSC to first reboot the server then install the SQL named instance
    - References:
        - https://docs.microsoft.com/en-us/powershell/scripting/dsc/configurations/reboot-a-node?view=powershell-7
        - https://docs.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server-with-powershell-desired-state-configuration?view=sql-server-ver15
        - https://github.com/dsccommunity/SqlServerDsc/wiki/SqlSetup

5. Install the IaaS extension
    - Solution: use another "deployement script" resource in an ARM template to install the extension
