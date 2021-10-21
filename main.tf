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

variable "domain_name" {
  type = string
}
variable "dc_admins_group_object_id" {
  type = string
  description = "the object id of the AAD DC Administrators Azure Active Directory group"
}
variable "drain_mode" {
  type = bool
  default = false
}
variable "ephemeral_os_disk" {
  type = bool
  default = false
}
variable "fs_logix" {
  type = bool
  default = true
}
variable "new_or_existing" {
  type = string
  default = "new"
}
variable "ou_path" {
  type = string
  default = "OU=AADDC Computers,DC=battelletest,DC=onmicrosoft,DC=us"
}
variable "resource_name_suffix" {
  type = string
  default = "mvtest"
}
# variable "security_principal_id" {
#   type = string
#   description = "the object id of the avd_users azure active directory group"
# }
variable "subnet" {
  type = string
  default = "avd-dev"
}
variable "virtual_network" {
  type = string
  default = "avd-dev"
}
variable "virtual_network_resource_group" {
  type = string
  default = "avd-dev"
}
variable "session_host_count" {
  type = number
  default = 1
}
variable "vm_password" {
  type = string
  default = "aaAA11223344"
}
variable "vm_username" {
  type = string
  default = "azadmin"
}
variable "wvd_object_id" {
  type = string
  description = "the object id of the Windows Virtual Desktop enterprise application for the tenant"
}
variable "recovery_services" {
  type = bool
  default = false
}
variable "image_sku" {
  type = string
  default = "20h2-ent-cpc-m365-g2"
}
variable "image_offer" {
  type = string
  default = "windows-ent-cpc"
}
variable "host_pool_type" {
  type = string
  default = "Pooled DepthFirst"
}
variable "max_session_limit" {
  type = number
  default = 1
}
variable "screen_capture_protection" {
  type = bool
  default = false
}
variable "custom_rdp_property" {
  type = string
  default = "audiocapturemode:i:1;camerastoredirect:s:*;use multimon:i:0;drivestoredirect:s:;redirectclipboard:i:0;redirectsmartcards:i:1"
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
  group_object_id  = "${var.dc_admins_group_object_id}"
  member_object_id = azuread_user.admin.object_id
}

resource "azurerm_subscription_template_deployment" "avd" {
    name = var.resource_name_suffix
    location = "usgovvirginia"
    template_content = file("./solutions/avd/solution.json")
    parameters_content = jsonencode({
      "DomainName": {
        "value": "${var.domain_name}"
      },
      "DomainServices": {
        "value": "ActiveDirectory"
      },
      "DomainJoinUserPrincipalName": {
        "value": "${local.user_principal_name}"
      },
      "DomainJoinPassword": {
        "value": "${local.user_principal_password}"
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
        "value": "${var.new_or_existing}"
      },
      "OuPath": {
        "value": "${var.ou_path}"
      },
      "ResourceNameSuffix": {
        "value": "${var.resource_name_suffix}"
      },
      "SecurityPrincipalId": {
        "value": "${azuread_group.avd_users.object_id}"
      },
      "SecurityPrincipalName": {
        "value": "${local.avd_users_group_name}"
      },
      "Subnet": {
        "value": "${var.subnet}"
      },
      "VirtualNetwork": {
        "value": "${var.virtual_network}"
      },
      "VirtualNetworkResourceGroup": {
        "value": "${var.virtual_network_resource_group}"
      },
      "SessionHostCount": {
        "value": var.session_host_count
      },
      "VmPassword": {
        "value": "${var.vm_password}"
      },
      "VmUsername": {
        "value": "${var.vm_username}"
      },
      "WvdObjectId": {
        "value": "${var.wvd_object_id}"
      },
      "Tags": {
        "value": {
          "Owner": "Matt Valerio",
          "Purpose": "POC",
          "Environment": "Dev"
        }
      },
      "RecoveryServices": {
        "value":  var.recovery_services
      },
      "ImageSku": {
        "value": "${var.image_sku}"
      },
      "ImageOffer": {
        "value": "${var.image_offer}"
      },
      "HostPoolType": {
        "value": "${var.host_pool_type}"
      },
      "MaxSessionLimit": {
        "value": var.max_session_limit
      },
      "ScreenCaptureProtection": {
        "value": var.screen_capture_protection
      },
      "CustomRdpProperty": {
        "value": "${var.custom_rdp_property}"
      }
    })
    # parameters_content = file("./parameters/test-parameters-valerio.json")
    # parameters_content = file("./parameters/battelleus-parameters-valerio.json")
}