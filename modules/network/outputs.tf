output "network_id" {
  description = "Network ID."
  value       = openstack_networking_network_v2.this.id
}

output "network_name" {
  description = "Network name."
  value       = openstack_networking_network_v2.this.name
}

output "subnet_ids" {
  description = "IDs of the created subnets (ordered as input)."
  value       = openstack_networking_subnet_v2.this[*].id
}

output "subnet_names" {
  description = "Names of the created subnets."
  value       = openstack_networking_subnet_v2.this[*].name
}

output "router_id" {
  description = "Router ID (null when create_router is false)."
  value       = var.create_router ? openstack_networking_router_v2.this[0].id : null
}
