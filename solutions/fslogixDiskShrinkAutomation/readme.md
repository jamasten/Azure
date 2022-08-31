# Azure Virtual Desktop - FSLogix Disk Shrink Automation

## Description

This solution will deploy a virtual machine weekly to run the Fslogix Disk Shrink tool against your SMB shares.  Once the tool has completed, the virtual machine is deleted to save on compute and storage charges. The following resources are deployed in this solution:

* Automation Account
  * Runbook
  * Webhook
  * Variable
* Key Vault
  * Secrets
* Logic App
* Role Assignments
