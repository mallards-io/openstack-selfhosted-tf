# Provider (VLAN) network per env: shared-<env> / shared-subnet-<env>.
module "shared_net" {
  source   = "../modules/network"
  for_each = var.environments

  name            = "shared-${each.key}"
  tenant_id       = data.openstack_identity_project_v3.host[each.key].id
  dns_nameservers = [var.dns_nameserver]
  segments = [{
    network_type     = "vlan"
    physical_network = var.provider_physical_network
    segmentation_id  = each.value.vlan
  }]
  subnets = [{
    name             = "shared-subnet-${each.key}"
    cidr             = each.value.provider_cidr
    gateway_ip       = each.value.provider_gw
    allocation_pools = [{ start = each.value.provider_pool.start, end = each.value.provider_pool.end }]
  }]
}

# Self-service network per env: tenant-<env> / tenant-subnet-<env>.
module "tenant_net" {
  source   = "../modules/network"
  for_each = var.environments

  name            = "tenant-${each.key}"
  tenant_id       = data.openstack_identity_project_v3.host[each.key].id
  dns_nameservers = [var.dns_nameserver]
  subnets = [{
    name       = "tenant-subnet-${each.key}"
    cidr       = each.value.selfservice_cidr
    gateway_ip = each.value.selfservice_gw
  }]
}

# One router per env bridging BOTH subnets to the external network.
resource "openstack_networking_router_v2" "env" {
  for_each = var.environments

  name                = "router-${each.key}"
  tenant_id           = data.openstack_identity_project_v3.host[each.key].id
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "tenant" {
  for_each = var.environments

  router_id = openstack_networking_router_v2.env[each.key].id
  subnet_id = module.tenant_net[each.key].subnet_ids[0]
}

resource "openstack_networking_router_interface_v2" "shared" {
  for_each = var.environments

  router_id = openstack_networking_router_v2.env[each.key].id
  subnet_id = module.shared_net[each.key].subnet_ids[0]
}
