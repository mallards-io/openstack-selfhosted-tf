# Mallards OpenStack — Networking (Shared VPC)

The **Shared VPC** layer, mirroring the GCP model and puppet's `shared_vpc.pp`.
Per environment (`dev`/`stg`/`prod`), a host project (`mall-network-<env>`) owns:

- a **provider (VLAN) network** `shared-<env>` / `shared-subnet-<env>` (`10.100.5x.0/24`)
- a **self-service network** `tenant-<env>` / `tenant-subnet-<env>` (`10.200.5x.0/24`)
- a **`router-<env>`** bridging both subnets to the `external` network
- **RBAC** (`access_as_shared`) sharing the networks + `fw-<env>-*` firewall SGs to the service project `mall-k8s-<env>`

**`cloudops` is isolated** — env #4 (VLAN 53, `10.100.53`/`10.200.53`), owned by
`mall-cloudops`, with the same shape but **no RBAC in or out**. It follows suite
on addressing; it just doesn't share.

Consumes the `network` + `security-group` modules (which now take `tenant_id` so a
central admin credential creates resources *in the host project*, and `segments`
for the provider VLAN nets). Auth + state: see the foundations repo README
(app-credential `clouds.yaml`, MinIO backend on mgmt).

## Adoption (existing dev/stg/prod already exist)

1. `terraform init`
2. `./import.sh` on the controller — review, then run **Part A** (import the
   networks/subnets/routers, which carry live ports and must not be recreated).
3. `terraform plan`. Expect:
   - dev/stg/prod nets/subnets/routers: no-op or in-place drift (dns/pool/tags).
   - **cloudops**: created fresh (net-new).
   - router interfaces / SG rules / consumer RBAC: TF wants to create them. Because
     those conflict with the puppet-made copies, finalize one of two ways:
     - **import** them once `plan` shows their addresses (surgical), or
     - delete the puppet-made firewall SGs + RBAC + interfaces and let TF recreate
       the firewall/RBAC layer in one apply (fine for a near-empty homelab).
4. Run **Part B** of `import.sh` to delete the stale cloudops→env RBAC policies.
5. Once green, retire puppet's `shared_vpc.pp` (Terraform is now the owner). Puppet
   keeps the Neutron *daemon* config.

> This is a live migration — run `plan` and iterate. cloudops applies cleanly on
> its own; the per-env adoption is the part that wants a careful plan review.

## Assumptions (adjust if needed)

- Import & adopt (not greenfield); cloudops CIDR `10.100.53`/`10.200.53` (next in sequence).
- Projects in the `mallards-io` domain; `external` net = router gateway; DNS `10.100.20.94`; SSH allowed from `10.100.20.0/24`.

## Conventions

- `terraform fmt --recursive` before committing. Conventional Commits (release-please).
