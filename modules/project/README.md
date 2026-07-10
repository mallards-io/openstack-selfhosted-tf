# OpenStack Project Terraform Module

Reusable module that manages a single Keystone project and its Nova/Neutron/Cinder quotas (`openstack_identity_project_v3` + the three `*_quotaset`/`quota` resources). It's the building block the **foundations** repo composes to create the `mall-*` tenancy.

Versioned module — consume by git ref/tag; provider and backend come from the calling (live) configuration.

## Usage

```hcl
module "k8s_dev" {
  source = "git::https://github.com/<org>/mallards-openstack-terraform-project.git?ref=v0.1.0"

  name        = "mall-k8s-dev"
  description = "Mallards Kubernetes Development Environment"
  tags        = ["tier:k8s", "env:dev"]

  compute_quota = { instances = 20, cores = 40, ram = 81920 }
  network_quota = { floatingip = 10 }
  storage_quota = { volumes = 50, gigabytes = 500 }
}
```

A host/network project that runs no compute (GCP host-project model):

```hcl
module "network_dev" {
  source = "git::https://github.com/<org>/mallards-openstack-terraform-project.git?ref=v0.1.0"

  name          = "mall-network-dev"
  tags          = ["tier:network", "env:dev"]
  compute_quota = { instances = 0, cores = 0, ram = 0 }
  network_quota = { network = 10, subnet = 20, port = 200, router = 5, floatingip = 10 }
}
```

## Notes

- Role bindings (attaching AD groups to roles) are handled in the **foundations** repo, not here — they're cross-project identity policy.
- `domain_id` null uses the provider's default domain; pass an explicit domain to place projects elsewhere.
- `terraform fmt --recursive` before committing. Releases via release-please (Conventional Commits).
