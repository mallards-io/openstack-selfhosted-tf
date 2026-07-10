output "id" {
  description = "Security group ID."
  value       = openstack_networking_secgroup_v2.this.id
}

output "name" {
  description = "Security group name."
  value       = openstack_networking_secgroup_v2.this.name
}

output "rule_ids" {
  description = "IDs of the created security group rules."
  value       = openstack_networking_secgroup_rule_v2.this[*].id
}
