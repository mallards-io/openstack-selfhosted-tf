output "id" {
  description = "Keypair ID."
  value       = openstack_compute_keypair_v2.this.id
}

output "name" {
  description = "Keypair name."
  value       = openstack_compute_keypair_v2.this.name
}

output "public_key" {
  description = "Public key material."
  value       = openstack_compute_keypair_v2.this.public_key
}

output "fingerprint" {
  description = "Keypair fingerprint."
  value       = openstack_compute_keypair_v2.this.fingerprint
}

output "private_key" {
  description = "Generated private key (only populated when public_key was not supplied)."
  value       = openstack_compute_keypair_v2.this.private_key
  sensitive   = true
}
