# Centralized firewall SGs owned by each host project: fw-<env>-{allow-internal,
# allow-ssh,allow-web,allow-icmp}. cloudops gets its own set too (for its own use).
module "firewall" {
  source   = "../modules/security-group"
  for_each = local.fw_sgs

  name        = "fw-${each.value.env}-${each.value.sg}"
  tenant_id   = data.openstack_identity_project_v3.host[each.value.env].id
  description = "central ${each.value.env} firewall: ${each.value.sg}"
  rules       = local.fw_rule_sets["${each.value.env}:${each.value.sg}"]
}
