# Azure Virtual Desktop - FSLogix Disk Shrink Automation

## Description

This solution will deploy a virtual machine weekly and run the [Invoke-FslShrinkDisk](https://github.com/FSLogix/Invoke-FslShrinkDisk/blob/master/Invoke-FslShrinkDisk.ps1) tool against your SMB shares.  Once the tool has completed, the virtual machine is deleted to save on compute and storage charges. The following resources are deployed in this solution:

* Automation Account
  * Runbook
  * Webhook
  * Variable
* Key Vault
  * Secrets
* Logic App
* Role Assignments
