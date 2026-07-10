# OpenStack Security Group Terraform Module

Reusable module that manages a Neutron security group and its rules (`openstack_networking_secgroup_v2` + `openstack_networking_secgroup_rule_v2`).

Versioned module — consume it by git ref/tag; the provider and backend come from the calling (live) configuration.

## Usage

```hcl
module "test_sg" {
  source = "git::https://github.com/<org>/mallards-openstack-terraform-security-group.git?ref=v0.1.0"

  name        = "test-sg"
  description = "test VM access"

  rules = [
    { direction = "ingress", protocol = "tcp", port_range_min = 22, port_range_max = 22, remote_ip_prefix = "0.0.0.0/0" },
    { direction = "ingress", protocol = "icmp", remote_ip_prefix = "0.0.0.0/0" },
  ]
}
```

## Notes

- `remote_ip_prefix` and `remote_group_id` are mutually exclusive per rule.
- Leave `protocol` unset for "any protocol".
- Run `terraform fmt --recursive` before committing. Releases via release-please (Conventional Commits).
