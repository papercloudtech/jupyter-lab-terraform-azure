variable "ssh_username" {
  type = string
}

variable "ssh_password" {
  type      = string
  sensitive = true
}

variable "jupyter_password" {
  type = string
  sensitive = true
  default = "1234"
}

variable "ssh_public_key_path" {
  type = string
  default = null
}

variable "resource_location" {
  type    = string
  default = "East US"

  validation {
    condition     = contains(["Australia Central", "Australia East", "Australia Southeast", "Canada Central", "Canada East", "Central India", "East Asia", "East US", "East US 2", "France Central", "Germany West Central", "Israel Central", "Italy North", "North Europe", "Norway East", "Poland Central", "South Africa North", "Sweden Central", "Switzerland North", "UAENorth", "UK South", "West US", "West US 3"], var.resource_location)
    error_message = "The location must be one of the specified Azure regions."
  }
}

variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}

variable "azure_subscription_id" {
  type      = string
  sensitive = true
  default   = null
}

variable "azure_tenant_id" {
  type      = string
  sensitive = true
  default   = null
}

variable "azure_client_id" {
  type      = string
  sensitive = true
  default   = null
}

variable "azure_client_secret" {
  type      = string
  sensitive = true
  default   = null
}
