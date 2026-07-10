# OpenStack Compute Instance Terraform Module

Reusable module that manages a single Nova instance (`openstack_compute_instance_v2`), with optional boot-from-volume. Every instance is tagged `managed-by = terraform`.

Versioned module — consume by git ref/tag; provider and backend come from the calling (live) configuration. Scale by calling it with `for_each`/`count`.

## Usage — the cloudops test VM

```hcl
module "test_vm" {
  source = "git::https://github.com/<org>/mallards-openstack-terraform-compute-instance.git?ref=v0.1.0"

  name            = "test-vm"
  image_name      = "ubuntu-22.04"
  flavor_name     = "m1.small"
  key_pair        = "ansible-key"
  security_groups = ["test-sg"]

  networks = [
    { name = "tenant-dev" },
  ]
}
```

Boot from a persistent Cinder volume instead of the ephemeral disk:

```hcl
  block_device = {
    volume_size = 20
    volume_type = "__DEFAULT__"
  }
```

## Notes

- Provide `image_name` **or** `image_id`, and `flavor_name` **or** `flavor_id`.
- `security_groups` must already exist (see the security-group module).
- `terraform fmt --recursive` before committing. Releases via release-please (Conventional Commits).
