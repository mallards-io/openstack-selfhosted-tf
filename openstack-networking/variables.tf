variable "os_cloud" {
  description = "clouds.yaml entry (Keystone application credential with admin, so it can create resources in host projects)."
  type        = string
  default     = "mallards-admin"
}

variable "ldap_domain_id" {
  description = "Keystone domain ID the mall-* projects live in (mallards-io). Set in terraform.tfvars."
  type        = string
}

variable "external_network_name" {
  description = "Name of the external/provider network used as router gateway."
  type        = string
  default     = "external"
}

variable "provider_physical_network" {
  description = "Neutron physical network name for the VLAN provider segments (ml2 physical_network)."
  type        = string
  default     = "provider"
}

variable "dns_nameserver" {
  description = "DNS nameserver assigned to subnets (the mgmt BIND server). Set in terraform.tfvars."
  type        = string
}

variable "fw_mgmt_cidr" {
  description = "Trusted management CIDR allowed to SSH into instances (allow-ssh rule). Set in terraform.tfvars."
  type        = string
}

variable "environments" {
  description = "Shared VPC topology per environment. Concrete CIDRs/VLANs live in terraform.tfvars. Set consumers = [] for an isolated stack (e.g. cloudops)."
  type = map(object({
    vlan          = number
    provider_cidr = string
    provider_gw   = string
    provider_pool = object({
      start = string
      end   = string
    })
    selfservice_cidr = string
    selfservice_gw   = string
    network_project  = string
    consumers        = list(string)
  }))
}
