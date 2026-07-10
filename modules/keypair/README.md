# OpenStack Keypair Terraform Module

Reusable module that manages a single Nova SSH keypair (`openstack_compute_keypair_v2`). Import an existing public key, or leave `public_key` empty to have OpenStack generate one (the private key is returned as a sensitive output).

Versioned module — consume it by git ref/tag; the provider and backend are supplied by the calling (live) configuration.

## Usage

```hcl
module "keypair" {
  source = "git::https://github.com/<org>/mallards-openstack-terraform-keypair.git?ref=v0.1.0"

  name       = "ansible-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}
```

Generate a keypair instead:

```hcl
module "keypair" {
  source = "git::https://github.com/<org>/mallards-openstack-terraform-keypair.git?ref=v0.1.0"
  name   = "test-generated"
}
# module.keypair.private_key  (sensitive)
```

## Notes

- Run `terraform fmt --recursive` before committing.
- Releases are automated with release-please (`terraform-module`); use Conventional Commits (`fix:` → patch, `feat:` → minor).
