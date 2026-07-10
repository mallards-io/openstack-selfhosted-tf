resource "openstack_networking_network_v2" "this" {
  region         = var.region
  name           = var.name
  tenant_id      = var.tenant_id
  admin_state_up = var.admin_state_up
  external       = var.external
  shared         = var.shared
  mtu            = var.mtu
  tags           = var.tags

  # Provider segments (VLAN/flat). Empty for a normal self-service network.
  dynamic "segments" {
    for_each = var.segments
    content {
      physical_network = segments.value.physical_network
      network_type     = segments.value.network_type
      segmentation_id  = segments.value.segmentation_id
    }
  }
}

resource "openstack_networking_subnet_v2" "this" {
  count = length(var.subnets)

  region          = var.region
  name            = var.subnets[count.index].name
  tenant_id       = var.tenant_id
  network_id      = openstack_networking_network_v2.this.id
  cidr            = var.subnets[count.index].cidr
  ip_version      = var.subnets[count.index].ip_version
  gateway_ip      = var.subnets[count.index].gateway_ip
  enable_dhcp     = var.subnets[count.index].enable_dhcp
  dns_nameservers = coalesce(var.subnets[count.index].dns_nameservers, var.dns_nameservers)

  dynamic "allocation_pool" {
    for_each = var.subnets[count.index].allocation_pools
    content {
      start = allocation_pool.value.start
      end   = allocation_pool.value.end
    }
  }
}

# Optional router: attaches all created subnets and (optionally) an external gateway.
# For multi-network routers (e.g. an SVPC router bridging a provider + self-service
# net), manage the router in the caller instead and leave create_router = false.
resource "openstack_networking_router_v2" "this" {
  count = var.create_router ? 1 : 0

  region              = var.region
  name                = "${var.name}-router"
  tenant_id           = var.tenant_id
  admin_state_up      = true
  external_network_id = var.external_network_id
  tags                = var.tags
}

resource "openstack_networking_router_interface_v2" "this" {
  count = var.create_router ? length(var.subnets) : 0

  region    = var.region
  router_id = openstack_networking_router_v2.this[0].id
  subnet_id = openstack_networking_subnet_v2.this[count.index].id
}
