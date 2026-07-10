variable "os_cloud" {
  description = "clouds.yaml entry to authenticate with (a Keystone application credential, not the admin password)."
  type        = string
  default     = "mallards-admin"
}

variable "ldap_domain_id" {
  description = "Keystone domain ID backing AD (mallards-io). The mall-* projects live here and AD groups resolve here. Set in terraform.tfvars: openstack domain show mallards-io -f value -c id."
  type        = string
}

variable "admin_role_name" {
  description = "Keystone role granted to the admin groups."
  type        = string
  default     = "admin"
}

variable "admin_groups" {
  description = "AD groups granted admin_role_name on every project (replaces the project scope of 07-setup-group-roles.sh)."
  type        = list(string)
  default     = ["Openstack_Admins", "Cloud_Engineer"]
}

variable "projects" {
  description = "The tenancy: project name => definition (description, tier/env tags, and Nova/Neutron/Cinder quotas). Concrete values live in terraform.tfvars."
  type = map(object({
    description = string
    tier        = string
    env         = string
    compute_quota = object({
      instances = number
      cores     = number
      ram       = number
      key_pairs = optional(number)
    })
    network_quota = object({
      network             = optional(number)
      subnet              = optional(number)
      port                = optional(number)
      router              = optional(number)
      floatingip          = optional(number)
      security_group      = optional(number)
      security_group_rule = optional(number)
    })
    storage_quota = optional(object({
      volumes   = optional(number)
      snapshots = optional(number)
      gigabytes = optional(number)
    }))
  }))
}
