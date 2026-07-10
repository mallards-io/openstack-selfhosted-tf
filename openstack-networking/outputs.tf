output "networks" {
  description = "Per-env network + router IDs."
  value = {
    for env in keys(var.environments) : env => {
      shared_network_id = module.shared_net[env].network_id
      tenant_network_id = module.tenant_net[env].network_id
      router_id         = openstack_networking_router_v2.env[env].id
    }
  }
}

output "firewall_sg_ids" {
  description = "Map of fw-<env>-<sg> => security group ID."
  value       = { for k, m in module.firewall : k => m.id }
}
