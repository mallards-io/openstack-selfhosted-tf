variable "name" {
  description = "Security group name."
  type        = string
}

variable "description" {
  description = "Security group description."
  type        = string
  default     = "Managed by Terraform"
}

variable "region" {
  description = "OpenStack region (defaults to the provider's region)."
  type        = string
  default     = null
}

variable "tenant_id" {
  description = "Project (tenant) ID that owns the security group and its rules. Null = the credential's own project. Set to place the SG in a host project (Shared VPC) via an admin credential."
  type        = string
  default     = null
}

variable "delete_default_rules" {
  description = "Delete the permissive egress rules OpenStack auto-creates with a new security group."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the security group."
  type        = list(string)
  default     = []
}

variable "rules" {
  description = "List of security group rules. Set remote_ip_prefix OR remote_group_id (not both); leave protocol null for 'any'."
  type = list(object({
    description      = optional(string)
    direction        = optional(string, "ingress")
    ethertype        = optional(string, "IPv4")
    protocol         = optional(string)
    port_range_min   = optional(number)
    port_range_max   = optional(number)
    remote_ip_prefix = optional(string)
    remote_group_id  = optional(string)
  }))
  default = []
}
