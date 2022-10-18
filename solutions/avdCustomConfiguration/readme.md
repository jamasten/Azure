# Azure Virtual Desktop - Custom Configuration solution

## Description

The Custom Configuration option is an Azure Portal feature of the AVD host pool deployment experience that allows VM extensions to be added to your AVD session hosts. Using the Custom Configuration, this solution deploys the Custom Script Extension to the session hosts. The Custom Script Extension runs a PowerShell script to install and dual-home the Microsoft Monitoring Agent to support log collection for AVD Insights and Azure Sentinel. The script also runs the [Virtual Desktop Optimization Tool](https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool) to improve user density on your AVD session hosts.

To use this solution, the JSON files must be saved to a publicly accessible storage location, like a public GitHub repository or a public Azure Blob Storage container. The PS1 file may be stored in a public storage location or a private Azure Blob Storage container.  If you choose to use a private container, setup a key vault secret with your SAS token and reference the secret in your parameters file.

## Implementation

1. Download the JSON and PS1 files to your computer.
1. Upload the script.ps1 file to your desired storage location.
1. Capture the URL for the script.ps1 file in a text editor.
1. Open the solution.parameters.json file in a text editor and update the values:
    1. AvdInsightsLogAnalyticsWorkspaceResourceId: input the resource ID for the Log Analytics Workspace dedicated to AVD Insights.
    1. Location: input the Azure deployment location for your AVD session hosts, i.e. eastus.
    1. NamePrefix: input the VM name prefix for each session host, i.e. avddeus.
    1. NumberOfVms: input the number of VM's for the deployment, i.e. 10.
    1. SasToken: (optional) input the SAS token for the Azure Blob Storage container for the PS1 file and if desired, the Virtual Desktop Optimization Tool.
    1. ScriptUri: input the URL for the script.ps1 file that was captured in a previous step, i.e. https://storage.blob.core.windows.net/avd/script.ps1.
    1. SentinelLogAnalyticsWorkspaceResourceId: input the resource ID of the existing Log Analytics Workspace used for Azure Sentinel.
    1. VirtualDesktopOptimizationToolUrl: input the URL of the ZIP file for the Virtual Desktop Optimization Tool.  The default value points to the GitHub repo for the tool and runs all the optimizations by default.  If desired, you can download your own copy of the tool, customize the optimizations, host it, and point to your own public URL.
    1. VirtualMachineIndex: input the number of the first VM in your deployment.  If this is your first deployment or you are performing a "rip and replace" then input 0.  To add VM's to your host pool, input the next number to deploy.  For example, if you deployed session hosts 0 through 5 in your first deployment, in your next deployment the index would be 6.
1. Save and close the solution.parameters.json file.
1. Upload the solution.json and solution.parameters.json files to your desired public storage location.
1. Capture the URL's for the JSON files in a text editor.
1. When deploying AVD session hosts from the Azure Portal, input the URL's to the JSON files in the input fields for the Custom Configuration.
