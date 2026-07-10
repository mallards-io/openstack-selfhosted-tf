# External/provider network used as every router's gateway.
data "openstack_networking_network_v2" "external" {
  name = var.external_network_name
}

# Host projects that own each env's networks (mall-network-*, and mall-cloudops for the isolated stack).
data "openstack_identity_project_v3" "host" {
  for_each  = var.environments
  name      = each.value.network_project
  domain_id = var.ldap_domain_id
}

# Consumer (service) projects that networks/SGs are shared to.
data "openstack_identity_project_v3" "consumer" {
  for_each  = local.consumers
  name      = each.value
  domain_id = var.ldap_domain_id
}
