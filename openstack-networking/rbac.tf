# Share each env's networks with its consumer (service) projects — the OpenStack
# equivalent of GCP Shared VPC subnet sharing. No entries for cloudops (isolated).
resource "openstack_networking_rbac_policy_v2" "network" {
  for_each = local.net_rbac

  object_type   = "network"
  object_id     = each.value.type == "shared" ? module.shared_net[each.value.env].network_id : module.tenant_net[each.value.env].network_id
  action        = "access_as_shared"
  target_tenant = data.openstack_identity_project_v3.consumer[each.value.consumer].id
}

# Share the centralized firewall SGs with the same consumers.
resource "openstack_networking_rbac_policy_v2" "firewall" {
  for_each = local.fw_rbac

  object_type   = "security_group"
  object_id     = module.firewall["${each.value.env}:${each.value.sg}"].id
  action        = "access_as_shared"
  target_tenant = data.openstack_identity_project_v3.consumer[each.value.consumer].id
}
