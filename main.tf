########################################
# Inputs
########################################

variable "custom_rdp_property" {
  type = string
  default = "audiocapturemode:i:1;camerastoredirect:s:*;use multimon:i:0;drivestoredirect:s:;redirectclipboard:i:0;redirectsmartcards:i:1"
  description = "Input RDP properties to add or remove RDP functionality on the AVD host pool. Settings reference: https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/rdp-files?context=/azure/virtual-desktop/context/context"
}
variable "dc_admins_group_object_id" {
  type = string
  description = "the object id of the AAD DC Administrators Azure Active Directory group"
}
variable "disk_encryption" {
  type = bool
  default = false
  description = "Enable BitLocker encrytion on the AVD session hosts and management VM, if applicable."
}
variable "disk_sku" {
  type = string
  default = "Standard_LRS"
  description = "The storage SKU for the AVD session host disks.  Production deployments should use 'Premium_LRS'."
}
variable "dod_stig_compliance" {
  type = bool
  default = true
  description = ""
}
variable "domain_name" {
  type = string
  description = "The name of the domain that provides ADDS to the AVD session hosts and is synchronized with Azure AD"
}
variable "domain_services" {
  type = string
  default = "AzureActiveDirectory"
  description = "The service providing domain services for Azure Virtual Desktop.  This is needed to determine the proper solution to domain join the Azure Storage Account."
}
variable "drain_mode" {
  type = bool
  default = false
  description = "Enable drain mode on sessions hosts during deployment to prevent users from accessing the session hosts."
}
variable "ephemeral_os_disk" {
  type = bool
  default = false
  description = "Choose whether the session host uses an ephemeral disk for the operating system.  Be sure to select a VM SKU that offers a temporary disk that meets your image requirements. Reference: https://docs.microsoft.com/en-us/azure/virtual-machines/ephemeral-os-disks"
}
variable "fs_logix" {
  type = bool
  default = true
  description = "Enable FSLogix to manage user profiles for the AVD session hosts."
}
variable "host_pool_type" {
  type = string
  default = "Pooled DepthFirst"
  description = "These options specify the host pool type and depending on the type, provides the load balancing options and assignment types."
}
variable "image_offer" {
  type = string
  default = "windows-ent-cpc"
  description = "Offer for the virtual machine image"
}
variable "image_sku" {
  type = string
  default = "20h2-ent-cpc-m365-g2"
  description = "SKU for the virtual machine image"
}
variable "image_publisher" {
  type = string
  default = "MicrosoftWindowsDesktop"
  description = "Publisher for the virtual machine image"
}
variable "image_version" {
  type = string
  default = "latest"
  description = "Version for the virtual machine image"
}
variable "kerberos_excryption_type" {
  type = string
  default = "RC4"
  description = "The Active Directory computer object Kerberos encryption type for the Azure Storage Account.  Allowed values are AES256 and RC4"
}
variable "log_analytics_workspace_retention" {
  type = number
  default = 30
  description = "The retention for the Log Analytics Workspace to setup the AVD Monitoring solution. Allowed values are from 30 to 730"
}
variable "log_analytics_workspace_sku" {
  type = string
  default = "PerGB2018"
  description = "The SKU for the Log Analytics Workspace to setup the AVD Monitoring solution.  Allowed values are Free, Standard, Premium, PerNode, PerGB2018, Standalone, and CapacityReservation"
}
variable "max_session_limit" {
  type = number
  default = 1
  description = "The maximum number of sessions per AVD session host."
}
variable "ou_path" {
  type = string
  description = "The distinguished name for the target Organization Unit in Active Directory Domain Services."
}
variable "rdp_short_path" {
  type = bool
  default = false
  description = "Enables the RDP Short Path feature: https://docs.microsoft.com/en-us/azure/virtual-desktop/shortpath"
}
variable "recovery_services" {
  type = bool
  default = false
  description = "Enable backups to an Azure Recovery Services vault.  For a pooled host pool, this will enable backups on the Azure file share.  For a personal host pool, this will enable backups on the AVD sessions hosts."
}
variable "resource_name_suffix" {
  type = string
  description = "Use letters and numbers only.  This suffix is used in conjunction with the resource type prefixes to name most of the Azure resources in this solution.  The only exception is the Storage Account since the value must globally unique and has stricter character requirements."
  validation {
    condition     = length(var.resource_name_suffix) < 11
    error_message = "The resource_name_suffix value must be no more than 10 characters long."
  }
}
variable "scaling_begin_peak_time" {
  type = string
  default = "9:00"
  description = "Time when session hosts will scale up and continue to stay on to support peak demand; Format 24 hours, e.g. 9:00 for 9am"
}
variable "scaling_end_peak_time" {
  type = string
  default = "17:00"
  description = "Time when session hosts will scale down and stay off to support low demand; Format 24 hours, e.g. 17:00 for 5pm"
}
variable "scaling_limit_seconds_to_force_log_off_user" {
  type = string
  default = "0"
  description = "The number of seconds to wait before automatically signing out users. If set to 0, any session host that has user sessions will be left untouched"
}
variable "scaling_minimum_number_of_rdsh" {
  type = string
  default = "0"
  description  = "The minimum number of session host VMs to keep running during off-peak hours. The scaling tool will not work if all VM's are turned off and the Start VM On Connect solution is not enabled."
}
variable "scaling_session_threshold_per_cpu" {
  type = string
  default = "1"
  description = "The maximum number of sessions per CPU that will be used as a threshold to determine when new session host VMs need to be started during peak hours"
}
variable "scaling_time_difference" {
  type = string
  default = "-4:00"
  description = "Time zone off set for host pool location; Format 24 hours, e.g. -4:00 for Eastern Daylight Time"
}
variable "screen_capture_protection" {
  type = bool
  default = false
  description = "Determines whether the Screen Capture Protection feature is enabled.  As of 9/17/21, this is only supported in Azure Cloud. https://docs.microsoft.com/en-us/azure/virtual-desktop/screen-capture-protection"
}
variable "session_host_count" {
  type = number
  default = 1
  description = "The number of session hosts to deploy in the host pool"
}
variable "session_host_index" {
  type = number
  default = 0
  description = "The session host number to begin with for the deployment. This is important when adding VM's to ensure the names do not conflict."
}
variable "start_vm_on_connect" {
  type = bool
  default = true
  description = "Determines whether the Start VM On Connect feature is enabled. https://docs.microsoft.com/en-us/azure/virtual-desktop/start-virtual-machine-connect"
}
variable "storage_account_sku" {
  type = string
  default = "Standard_LRS"
  description = "The SKU for the Azure storage account containing the AVD user profile data.  The selected SKU should provide sufficient IOPS for all of your users. https://docs.microsoft.com/en-us/azure/architecture/example-scenario/wvd/windows-virtual-desktop-fslogix#performance-requirements.  Allowed values are Standard_LRS and Premium_LRS"
}
variable "subnet" {
  type = string
  description = "The subnet for the AVD session hosts."
}
variable "validation_environment" {
  type = bool
  default = false
  description = "The value determines whether the hostpool should receive early AVD updates for testing."
}
variable "virtual_network" {
  type = string
  description = "Virtual network for the AVD sessions hosts"
}
variable "virtual_network_resource_group" {
  type = string
  description = "Virtual network resource group for the AVD sessions hosts"
}
variable "vm_password" {
  type = string
  default = "aaAA11223344"
  description = "Local administrator password for the AVD session hosts"
}
variable "vm_size" {
  type = string
  default = "Standard_B2s"
  description = "The VM size for the AVD session hosts."
}
variable "vm_username" {
  type = string
  default = "azadmin"
  description = "The Local Administrator Username for the Session Hosts"
}
variable "wvd_object_id" {
  type = string
  description = "the object id of the Azure Virtual Desktop enterprise application for the tenant"
}

locals {
  user_principal_name = "avd-${var.resource_name_suffix}-temp-admin-user@${var.domain_name}"
  user_principal_password = "Pa55w0Rd!!1"
  avd_users_group_name = "avd_users_${var.resource_name_suffix}"
}

#setup the avd_users_group
resource "azuread_group" "avd_users" {
  display_name = local.avd_users_group_name
  security_enabled = true
}

# create a temporary user that will be used to join vms to the domain
resource "azuread_user" "admin" {
  user_principal_name = local.user_principal_name
  display_name        = "AVD ${var.resource_name_suffix} DC Administrator"
  password            = local.user_principal_password
}

resource "azuread_group_member" "admin" {
  group_object_id  = var.dc_admins_group_object_id
  member_object_id = azuread_user.admin.object_id
}

resource "azurerm_subscription_template_deployment" "avd" {
    name = var.resource_name_suffix
    depends_on = [
      azuread_group.avd_users,
      azuread_user.admin,
      azuread_group_member.admin
    ]
    location = "usgovvirginia"
    template_content = file(".terraform/modules/avd/solutions/avd/solution.json")
    parameters_content = jsonencode({
      "AvdObjectId": {
        "value": var.wvd_object_id
      },
      "CustomRdpProperty": {
        "value": var.custom_rdp_property
      },
      "DiskEncryption": {
        "value": var.disk_encryption
      },
      "DiskSku": {
        "value": var.disk_sku
      },
      "DodStigCompliance": {
        "value": var.dod_stig_compliance
      }
      "DomainName": {
        "value": var.domain_name
      },
      "DomainServices": {
        "value": var.domain_services
      },
      "DomainJoinUserPrincipalName": {
        "value": local.user_principal_name
      },
      "DomainJoinPassword": {
        "value": local.user_principal_password
      },
      "DrainMode": {
        "value": var.drain_mode
      },
      "EphemeralOsDisk": {
        "value": var.ephemeral_os_disk
      },
      "FSLogix": {
        "value": var.fs_logix
      },
      "ImageOffer": {
        "value": var.image_offer
      },
      "ImagePublisher": {
        "value": var.image_publisher
      }
      "ImageSku": {
        "value": var.image_sku
      },
      "ImageVersion": {
        "value": var.image_version
      },
      "KerberosEncryption": {
        "value": var.kerberos_excryption_type
      },
      "LogAnalyticsWorkspaceRetention": {
        "value": var.log_analytics_workspace_retention
      },
      "LogAnalyticsWorkspaceSku": {
        "value": var.log_analytics_workspace_sku
      },
      "OuPath": {
        "value": var.ou_path
      },
      "RdpShortPath": {
        "value": var.rdp_short_path
      },
      "ResourceNameSuffix": {
        "value": var.resource_name_suffix
      },
      "ScalingBeginPeakTime": {
        "value": var.scaling_begin_peak_time
      },
      "ScalingEndPeakTime": {
        "value": var.scaling_end_peak_time
      },
      "ScalingLimitSecondsToForceLogOffUser": {
        "value": var.scaling_limit_seconds_to_force_log_off_user
      },
      "ScalingMinimumNumberOfRdsh": {
        "value": var.scaling_minimum_number_of_rdsh
      }
      "ScalingSessionThresholdPerCPU": {
        "value": var.scaling_session_threshold_per_cpu
      },
      "ScalingTimeDifference": {
        "value": var.scaling_time_difference
      },
      "ScreenCaptureProtection": {
        "value": var.screen_capture_protection
      },
      "SecurityPrincipalId": {
        "value": azuread_group.avd_users.object_id
      },
      "SecurityPrincipalName": {
        "value": local.avd_users_group_name
      },
      "SessionHostCount": {
        "value": var.session_host_count
      },
      "SessionHostIndex": {
        "value": var.session_host_index
      },
      "StartVmOnConnect": {
        "value": var.start_vm_on_connect
      },
      "StorageAccountSku": {
        "value": var.storage_account_sku
      },
      "Subnet": {
        "value": var.subnet
      },
      "Tags": {
        "value": {
          # "Owner": "${data.azuread_user.current_user.user_principal_name}",
          "Purpose": "POC",
          "Environment": "Dev"
        }
      },
      "ValidationEnvironment": {
        "value": var.validation_environment
      },
      "VirtualNetwork": {
        "value": var.virtual_network
      },
      "VirtualNetworkResourceGroup": {
        "value": var.virtual_network_resource_group
      },
      "VmPassword": {
        "value": var.vm_password
      },
      "VmSize": {
        "value": var.vm_size
      },
      "VmUsername": {
        "value": var.vm_username
      },
      "RecoveryServices": {
        "value":  var.recovery_services
      },
      "HostPoolType": {
        "value": var.host_pool_type
      },
      "MaxSessionLimit": {
        "value": var.max_session_limit
      }
    })
}