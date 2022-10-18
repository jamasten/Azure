# Azure Virtual Desktop - Custom Configuration solution

## Description

The Custom Configuration option is an Azure Portal feature of the AVD host pool deployment experience that allows VM extensions to be added to your AVD session hosts. Using the Custom Configuration feature, this solution deploys the Microsoft Monitoring Agent and Custom Script Extension to the session hosts. The Microsoft Monitoring Agent extension installs the agent and configures the primary log analytics workspace for AVD Insights. The Custom Script Extension runs a PowerShell script to dual-home the Microsoft Monitoring Agent to support log collection for Azure Sentinel. The script also runs the [Virtual Desktop Optimization Tool (VDOT)](https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool) to improve user density on your AVD session hosts.

To use this solution, the JSON files must be saved to a publicly accessible storage location, like a public GitHub repository or a public Azure Blob Storage container. The PS1 file may be stored in a public storage location or a private Azure Blob Storage container. VDOT may be downloaded directly from their GitHub repository if you want to use the default customizations. However, if you want to make changes to the customization files, you will need to host it in an Azure Blob Storage container. If you choose to use a private container for the PS1 file and / or VDOT, you will need to setup a key vault secret with your SAS token and reference the secret in your parameters file.  The SAS token should be created at the container scope with Read permissions.

## Implementation

1. Download the files to your computer. If desired, download VDOT to make customization changes.
1. Modify the PS1 file and / or VDOT to support your desired configuration.
1. Upload the PS1 file and / or VDOT to your desired storage location.
1. Capture the URL for the PS1 file and / or VDOT in a text editor.
1. Open the solution.parameters.json file in a text editor and update the values:
    1. AvdInsightsLogAnalyticsWorkspaceResourceId: input your resource ID for the log analytics workspace dedicated to AVD Insights.
    1. Location: input your Azure deployment location for the AVD session hosts, i.e. eastus.
    1. NamePrefix: input the VM name prefix for each session host, i.e. avddeus.
    1. NumberOfVms: input your number of virtual machines for the deployment, i.e. 10.
    1. SasToken: (optional) input your SAS token for the private Azure Blob Storage container for the PS1 file and / or VDOT.
    1. ScriptUri: input the URL for the script.ps1 file that was captured in a previous step, i.e. https://storage.blob.core.windows.net/avd/script.ps1.
    1. SentinelLogAnalyticsWorkspaceResourceId: input your resource ID of the existing Log Analytics Workspace dedicated to Azure Sentinel.
    1. VirtualDesktopOptimizationToolUrl: input the URL of the ZIP file for VDOT. The default value points to the GitHub repo for the tool and runs all the default optimizations.  If desired, you can download your own copy of the tool, customize the optimizations, host it, and point to your own URL.
    1. VirtualMachineIndex: input the number of the first VM in your deployment.  If this is your first deployment or you are performing a "rip and replace" then input 0.  To add VM's to your host pool, input the next number to deploy.  For example, if you deployed session hosts 0 through 5 in your first deployment, in your next deployment the index would be 6.
1. Save and close the solution.parameters.json file.
1. Upload the JSON files to your desired public storage location.
1. Capture the URLs for the JSON files in a text editor.
1. When deploying AVD session hosts from the Azure Portal, input the URL's to the JSON files in the input fields for the Custom Configuration feature.
