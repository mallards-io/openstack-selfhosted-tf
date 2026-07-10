output "project_ids" {
  description = "Map of project name => ID (consumed by the networking + workload repos)."
  value       = { for k, m in module.project : k => m.id }
}

output "project_names" {
  description = "List of managed project names."
  value       = keys(var.projects)
}
