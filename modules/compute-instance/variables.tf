variable "name" {
  description = "Instance name."
  type        = string
}

variable "region" {
  description = "OpenStack region (defaults to the provider's region)."
  type        = string
  default     = null
}

variable "image_name" {
  description = "Boot image name (use this or image_id)."
  type        = string
  default     = null
}

variable "image_id" {
  description = "Boot image ID (use this or image_name)."
  type        = string
  default     = null
}

variable "flavor_name" {
  description = "Flavor name (use this or flavor_id)."
  type        = string
  default     = null
}

variable "flavor_id" {
  description = "Flavor ID (use this or flavor_name)."
  type        = string
  default     = null
}

variable "key_pair" {
  description = "Nova keypair name for SSH access."
  type        = string
  default     = null
}

variable "security_groups" {
  description = "Security groups to attach."
  type        = list(string)
  default     = ["default"]
}

variable "availability_zone" {
  description = "Availability zone to schedule into."
  type        = string
  default     = null
}

variable "user_data" {
  description = "cloud-init user-data."
  type        = string
  default     = null
}

variable "config_drive" {
  description = "Attach a config drive (useful when metadata service is unavailable)."
  type        = bool
  default     = false
}

variable "networks" {
  description = "Networks to attach; give name or uuid per entry."
  type = list(object({
    name        = optional(string)
    uuid        = optional(string)
    fixed_ip_v4 = optional(string)
    port        = optional(string)
  }))
}

variable "metadata" {
  description = "Instance metadata (merged with managed-by=terraform)."
  type        = map(string)
  default     = {}
}

variable "block_device" {
  description = "Optional boot-from-volume config. Null = boot from the image's ephemeral disk."
  type = object({
    source_type           = optional(string, "image")
    volume_size           = number
    volume_type           = optional(string)
    delete_on_termination = optional(bool, true)
  })
  default = null
}
