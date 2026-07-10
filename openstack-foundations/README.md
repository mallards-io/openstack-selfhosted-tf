# Mallards OpenStack — Foundations

The **landing zone** for the Mallards OpenStack cloud, in Terraform: the tenancy
(`mall-*` projects), their Nova/Neutron/Cinder quotas, and the AD-group → role
bindings that grant admin. This is the OpenStack analog of a GCP foundations
repo (org/folders/projects/IAM).

It composes the versioned [`mallards-openstack-terraform-project`](../mallards-openstack-terraform-project) module.

## Scope (and what it deliberately does NOT do)

- **Manages:** projects, quotas, and `admin_groups → admin` role bindings on each project.
- **Does not manage users/groups:** human identities live in **Samba AD** and are
  read-only in Keystone (`user_allow_create = false`). Terraform resolves the AD
  groups (`Openstack_Admins`, `Cloud_Engineer`) and binds them — it cannot create them.
- **Leaves to puppet:** the Keystone/Neutron/Nova *daemon* config, service users,
  endpoints, and the LDAP domain backend (host config, not tenancy).

## Migration posture — import & adopt (assumed default)

These projects already exist (puppet created them). This repo is written to
**adopt** them, not recreate them. Order of operations:

1. `terraform init`
2. `./import.sh | bash` on the controller (adopts projects + quotasets into state).
3. `terraform plan` — should show **no destroys/creates** for projects/quotas
   (only, at most, tag/quota drift to reconcile) plus role-binding reconciliation.
4. Once green, **retire the puppet resource execs** so the two tools don't fight:
   `project.pp`, the `07-setup-group-roles.sh` project-scope assignments, and
   (after the networking repo lands) `shared_vpc.pp`. Puppet keeps daemon/service config.

> NOTE: the takeover strategy (import/adopt vs greenfield vs parallel) and the
> domain layout were assumed (import+adopt, keep current `mallards-io` domain)
> because the choice was pending. Adjust `locals.tf`/`variables.tf` if you decide differently.

## Auth — application credential (not the admin password)

On the controller:

```bash
. /root/mall-cloudops-openrc   # or admin-openrc
openstack application credential create tf-foundations --role admin
```

Put it in `~/.config/openstack/clouds.yaml` under the name in `var.os_cloud` (`mallards-admin`):

```yaml
clouds:
  mallards-admin:
    auth_type: v3applicationcredential
    auth:
      auth_url: http://controller.mallards.io:5000/v3
      application_credential_id: "<id>"
      application_credential_secret: "<secret>"
    region_name: RegionOne
```

## State — MinIO on mgmt (independent plane)

State must NOT live in Swift (circular). Stand up MinIO on mgmt (`10.100.20.94`),
create a bucket `mallards-tfstate`, then uncomment the `backend "s3"` block in
`backend.tf` and `terraform init -migrate-state`. Credentials via
`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`.

## Module sourcing

Local dev uses a relative path (`../mallards-openstack-terraform-project`) so it
validates side-by-side. In CI, pin to a tag: `git::https://github.com/<org>/mallards-openstack-terraform-project.git?ref=v0.1.0`.

## Conventions

- `terraform fmt --recursive` before committing.
- Conventional Commits (release-please).
