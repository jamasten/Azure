terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.6.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.80.0"
    }
  }
}
provider "azuread" {
  environment = "usgovernment"
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

########################################
# Inputs
########################################

variable "disk_encryption" {
  type = bool
  default = true
  description = "Enable BitLocker encrytion on the AVD session hosts and management VM, if applicable."
}
variable "domain_name" {
  type = string
  description = "The name of the domain that provides ADDS to the AVD session hosts and is synchronized with Azure AD"
}
variable "dc_admins_group_object_id" {
  type = string
  description = "the object id of the AAD DC Administrators Azure Active Directory group"
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
variable "new_or_existing" {
  type = string
  default = "new"
  description = "Sets whether this is the first deployment of this solution or is a follow up deployment to add new or additional AVD session hosts."
}
variable "ou_path" {
  type = string
  default = "OU=AADDC Computers,DC=battelletest,DC=onmicrosoft,DC=us"
  description = "The distinguished name for the target Organization Unit in Active Directory Domain Services."
}
variable "resource_name_suffix" {
  type = string
  description = "Use letters and numbers only.  This suffix is used in conjunction with the resource type prefixes to name most of the Azure resources in this solution.  The only exception is the Storage Account since the value must globally unique and has stricter character requirements."
}
variable "subnet" {
  type = string
  default = "avd-dev"
  description = "The subnet for the AVD session hosts."
}
variable "virtual_network" {
  type = string
  default = "avd-dev"
  description = "Virtual network for the AVD sessions hosts"
}
variable "virtual_network_resource_group" {
  type = string
  default = "avd-dev"
  description = "Virtual network resource group for the AVD sessions hosts"
}
variable "session_host_count" {
  type = number
  default = 1
  description = "The number of session hosts to deploy in the host pool"
}
variable "vm_password" {
  type = string
  default = "aaAA11223344"
  description = "Local administrator password for the AVD session hosts"
}
variable "vm_username" {
  type = string
  default = "azadmin"
  description = "The Local Administrator Username for the Session Hosts"
}
variable "wvd_object_id" {
  type = string
  description = "the object id of the Windows Virtual Desktop enterprise application for the tenant"
}
variable "recovery_services" {
  type = bool
  default = false
  description = "Enable backups to an Azure Recovery Services vault.  For a pooled host pool, this will enable backups on the Azure file share.  For a personal host pool, this will enable backups on the AVD sessions hosts."
}
variable "image_sku" {
  type = string
  default = "20h2-ent-cpc-m365-g2"
  description = "SKU for the virtual machine image"
}
variable "image_offer" {
  type = string
  default = "windows-ent-cpc"
  description = "Offer for the virtual machine image"
}
variable "host_pool_type" {
  type = string
  default = "Pooled DepthFirst"
  description = "These options specify the host pool type and depending on the type, provides the load balancing options and assignment types."
}
variable "max_session_limit" {
  type = number
  default = 1
  description = "The maximum number of sessions per AVD session host."
}
variable "screen_capture_protection" {
  type = bool
  default = false
  description = "Determines whether the Screen Capture Protection feature is enabled.  As of 9/17/21, this is only supported in Azure Cloud. https://docs.microsoft.com/en-us/azure/virtual-desktop/screen-capture-protection"
}
variable "custom_rdp_property" {
  type = string
  default = "audiocapturemode:i:1;camerastoredirect:s:*;use multimon:i:0;drivestoredirect:s:;redirectclipboard:i:0;redirectsmartcards:i:1"
  description = "Input RDP properties to add or remove RDP functionality on the AVD host pool. Settings reference: https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/clients/rdp-files?context=/azure/virtual-desktop/context/context"
}

locals {
  user_principal_name = "avd-${var.resource_name_suffix}-temp-admin-user@${var.domain_name}"
  user_principal_password = "Pa55w0Rd!!1"
  avd_users_group_name = "avd_users_${var.resource_name_suffix}"
}

data "azurerm_client_config" "current" {}

data "azuread_user" "current_user" {
  object_id = data.azurerm_client_config.current.object_id
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
    location = "usgovvirginia"
    template_content = file("./solutions/avd/solution.json")
    parameters_content = jsonencode({
      "DiskEncryption": {
        "value": var.disk_encryption
      }
      "DomainName": {
        "value": var.domain_name
      },
      "DomainServices": {
        "value": "ActiveDirectory"
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
      "newOrExisting": {
        "value": var.new_or_existing
      },
      "OuPath": {
        "value": var.ou_path
      },
      "ResourceNameSuffix": {
        "value": var.resource_name_suffix
      },
      "SecurityPrincipalId": {
        "value": azuread_group.avd_users.object_id
      },
      "SecurityPrincipalName": {
        "value": local.avd_users_group_name
      },
      "Subnet": {
        "value": var.subnet
      },
      "VirtualNetwork": {
        "value": var.virtual_network
      },
      "VirtualNetworkResourceGroup": {
        "value": var.virtual_network_resource_group
      },
      "SessionHostCount": {
        "value": var.session_host_count
      },
      "VmPassword": {
        "value": var.vm_password
      },
      "VmUsername": {
        "value": var.vm_username
      },
      "WvdObjectId": {
        "value": var.wvd_object_id
      },
      "Tags": {
        "value": {
          "Owner": "${data.azuread_user.current_user.user_principal_name}",
          "Purpose": "POC",
          "Environment": "Dev"
        }
      },
      "RecoveryServices": {
        "value":  var.recovery_services
      },
      "ImageSku": {
        "value": var.image_sku
      },
      "ImageOffer": {
        "value": var.image_offer
      },
      "HostPoolType": {
        "value": var.host_pool_type
      },
      "MaxSessionLimit": {
        "value": var.max_session_limit
      },
      "ScreenCaptureProtection": {
        "value": var.screen_capture_protection
      },
      "CustomRdpProperty": {
        "value": var.custom_rdp_property
      }
    })
}