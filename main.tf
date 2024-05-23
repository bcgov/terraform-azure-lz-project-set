terraform {
  required_version = "1.8.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.103.1"
    }
    azapi = {
      source  = "azure/azapi"
      version = "1.13.1"
    }
  }
}

data "azurerm_management_group" "landing_zones" {
  name = var.lz_management_group_id
}

# create a management group for the project set
resource "azurerm_management_group" "project_set" {
  name                       = var.license_plate
  display_name               = "${var.license_plate}: ${var.project_set_name}"
  parent_management_group_id = data.azurerm_management_group.landing_zones.id
}

module "lz_vending" {
  source  = "Azure/lz-vending/azurerm"
  version = "4.1.0"

  for_each = var.subscriptions

  # Set the default location for resources
  location = var.primary_location

  # subscription variables
  subscription_alias_enabled = true
  subscription_billing_scope = var.subscription_billing_scope
  subscription_display_name  = "${var.license_plate}-${each.value.name}"
  subscription_alias_name    = "${var.license_plate}-${each.value.name}"
  subscription_workload      = "Production"

  network_watcher_resource_group_enabled = true

  # management group association variables
  subscription_management_group_association_enabled = true
  subscription_management_group_id                  = var.license_plate

  # virtual network variables
  virtual_network_enabled = each.value.network.enabled
  virtual_networks = each.value.network.enabled ? {
    vwan_spoke = {
      name                    = "${var.license_plate}-${each.value.name}-vwan-spoke"
      address_space           = each.value.network.address_space
      resource_group_name     = "${var.license_plate}-${each.value.name}-networking"
      vwan_connection_enabled = true
      vwan_hub_resource_id    = var.vwan_hub_resource_id
      tags                    = var.common_tags
    }
  } : {}

  budget_enabled = each.value.budget_amount > 0

  budgets = {
    registry = {
      amount            = each.value.budget_amount
      time_grain        = "Monthly"
      time_period_start = formatdate("YYYY-MM-01T00:00:00Z", timestamp())
      time_period_end   = formatdate("YYYY-MM-01T00:00:00Z", timeadd(timestamp(), "87600h")) // 10 years from now
      notifications = {
        eightypercent = {
          enabled        = true
          operator       = "GreaterThan"
          threshold      = 80
          threshold_type = "Actual"
          contact_groups = ["Owner"]
        }
        budgetexceeded = {
          enabled        = true
          operator       = "GreaterThan"
          threshold      = 100
          threshold_type = "Forecasted"
          contact_groups = ["Owner"]
        }
      }
    }
  }
}
