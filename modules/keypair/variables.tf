variable "name" {
  description = "Name of the keypair."
  type        = string
}

variable "public_key" {
  description = "Existing SSH public key to import. Leave empty to have OpenStack generate a keypair (private key returned as a sensitive output)."
  type        = string
  default     = ""
}

variable "region" {
  description = "OpenStack region (defaults to the provider's region)."
  type        = string
  default     = null
}
