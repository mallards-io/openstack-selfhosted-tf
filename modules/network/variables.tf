variable "name" {
  description = "Network name."
  type        = string
}

variable "region" {
  description = "OpenStack region (defaults to the provider's region)."
  type        = string
  default     = null
}

variable "tenant_id" {
  description = "Project (tenant) ID that OWNS the network/subnets/router. Null = the credential's own project. Set this to create resources in a host project (Shared VPC) using an admin credential."
  type        = string
  default     = null
}

variable "admin_state_up" {
  description = "Administrative state of the network."
  type        = bool
  default     = true
}

variable "external" {
  description = "Mark the network as external (provider network with an uplink)."
  type        = bool
  default     = false
}

variable "shared" {
  description = "Share the network across all projects (admin only). For scoped sharing prefer RBAC."
  type        = bool
  default     = false
}

variable "mtu" {
  description = "Network MTU (null = provider default)."
  type        = number
  default     = null
}

variable "segments" {
  description = "Provider network segments (VLAN/flat). Empty for a normal self-service network. e.g. [{ network_type = \"vlan\", physical_network = \"provider\", segmentation_id = 50 }]."
  type = list(object({
    physical_network = optional(string)
    network_type     = string
    segmentation_id  = optional(number)
  }))
  default = []
}

variable "dns_nameservers" {
  description = "Default DNS nameservers applied to any subnet that does not set its own."
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Subnets to create on this network."
  type = list(object({
    name            = string
    cidr            = string
    ip_version      = optional(number, 4)
    gateway_ip      = optional(string)
    enable_dhcp     = optional(bool, true)
    dns_nameservers = optional(list(string))
    allocation_pools = optional(list(object({
      start = string
      end   = string
    })), [])
  }))
  default = []
}

variable "create_router" {
  description = "Create a router and attach every subnet to it. Leave false when a caller-managed router bridges multiple networks."
  type        = bool
  default     = false
}

variable "external_network_id" {
  description = "External network ID for the router's gateway (used when create_router is true)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the network and router."
  type        = list(string)
  default     = []
}
