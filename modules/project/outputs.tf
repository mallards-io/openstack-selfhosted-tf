output "id" {
  description = "Project ID."
  value       = openstack_identity_project_v3.this.id
}

output "name" {
  description = "Project name."
  value       = openstack_identity_project_v3.this.name
}

output "domain_id" {
  description = "Domain ID the project belongs to."
  value       = openstack_identity_project_v3.this.domain_id
}
