# OpenStack Network Terraform Module

Reusable module that manages a Neutron network, its subnets, and an optional router (`openstack_networking_network_v2`, `_subnet_v2`, `_router_v2`, `_router_interface_v2`).

Versioned module — consume by git ref/tag; provider and backend come from the calling (live) configuration.

## Usage

```hcl
module "app_net" {
  source = "git::https://github.com/<org>/mallards-openstack-terraform-network.git?ref=v0.1.0"

  name            = "app-net"
  dns_nameservers = ["10.100.20.94"]

  subnets = [
    { name = "app-subnet", cidr = "192.168.50.0/24" },
  ]

  create_router       = true
  external_network_id = data.openstack_networking_network_v2.external.id
}
```

## Notes

- `shared` uses global sharing (admin). For per-project sharing, use Neutron RBAC (managed separately, e.g. in puppet's shared-VPC layer).
- A router with `external_network_id` gives attached subnets SNAT/uplink — required for guests to reach off-network services.
- `terraform fmt --recursive` before committing. Releases via release-please (Conventional Commits).
