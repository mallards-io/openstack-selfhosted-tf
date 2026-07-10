output "id" {
  description = "Instance ID."
  value       = openstack_compute_instance_v2.this.id
}

output "name" {
  description = "Instance name."
  value       = openstack_compute_instance_v2.this.name
}

output "access_ip_v4" {
  description = "Primary IPv4 address selected by Nova."
  value       = openstack_compute_instance_v2.this.access_ip_v4
}

output "network" {
  description = "All attached networks and their addresses."
  value       = openstack_compute_instance_v2.this.network
}

output "all_metadata" {
  description = "Effective instance metadata."
  value       = openstack_compute_instance_v2.this.all_metadata
}
