variable "name" {
  description = "Project name."
  type        = string
}

variable "description" {
  description = "Project description."
  type        = string
  default     = "Managed by Terraform"
}

variable "domain_id" {
  description = "Domain ID the project belongs to (null = provider's default domain)."
  type        = string
  default     = null
}

variable "enabled" {
  description = "Whether the project is enabled."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Project tags (used here to express the GCP-style tier/env hierarchy, e.g. tier:k8s, env:dev)."
  type        = list(string)
  default     = []
}

variable "compute_quota" {
  description = "Nova quota. Null leaves the deployment default. Set instances/cores/ram = 0 for host/network projects that run no compute."
  type = object({
    instances = number
    cores     = number
    ram       = number
    key_pairs = optional(number)
  })
  default = null
}

variable "network_quota" {
  description = "Neutron quota. Null leaves the deployment default."
  type = object({
    network             = optional(number)
    subnet              = optional(number)
    port                = optional(number)
    router              = optional(number)
    floatingip          = optional(number)
    security_group      = optional(number)
    security_group_rule = optional(number)
  })
  default = null
}

variable "storage_quota" {
  description = "Cinder quota. Null leaves the deployment default."
  type = object({
    volumes   = optional(number)
    snapshots = optional(number)
    gigabytes = optional(number)
  })
  default = null
}
