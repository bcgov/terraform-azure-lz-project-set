variable "primary_location" {
  description = "The primary location for resources"
  type        = string
  default     = "canadacentral"
}

variable "secondary_location" {
  description = "The secondary location for resources"
  type        = string
  default     = "canadaeast"
}

variable "subscription_billing_scope" {
  description = "The billing scope for the subscription"
  type        = string
}

variable "lz_management_group_id" {
  description = "The ID of the management group for landing zones"
  type        = string
}

variable "vwan_hub_resource_id" {
  description = "The resource ID for the virtual WAN hub"
  type        = string
}

variable "license_plate" {
  description = "The license plate identifier for the project"
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9]{5}$", var.license_plate))
    error_message = "The license plate must start with a letter, contain only lowercase letters and numbers, and be exactly 6 characters long."
  }
}

variable "project_set_name" {
  description = "The name of the project set"
  type        = string
}

variable "subscriptions" {
  description = "Configuration details for each subscription"
  type = map(object({
    name : string
    display_name : string
    budget_amount : optional(number, 0)
    network : object({
      enabled : bool
      address_space : list(string)
    })
  }))
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    deployedBy = "Terraform"
  }
}
