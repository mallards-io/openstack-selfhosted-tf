# Self-Hosted OpenStack Platform — GitOps IaC on Baremetal

A private cloud, built from scratch. Baremetal **OpenStack** (controller + compute) is stood up
with **Ansible** and kept in configuration with **Puppet**. A self-hosted control plane —
**GitLab + Atlantis**, with **MinIO** as the S3-compatible Terraform state backend — then manages
OpenStack as code: the tenancy (projects, quotas, identity) and a **GCP-style Shared-VPC** network
topology are applied by **Terraform through merge requests**, never by hand.

> **What this demonstrates** (built entirely on my own baremetal — no employer/client code):
> foundational **network engineering** (Shared-VPC design, VLANs, routers, RBAC, firewalling),
> **Terraform IaC** at an org-foundation level, **IaC-as-GitOps** (Atlantis on merge requests),
> **secretless automation** (Vault + Keystone application credentials — no creds in code), and
> full-stack platform bring-up (Ansible/Puppet). The Shared-VPC modeling is a deliberate bridge
> to a GCP shop's mental model.

---

## Table of contents
1. [Architecture](#architecture)
2. [The stack, layer by layer](#the-stack-layer-by-layer)
3. [The GitOps IaC flow](#the-gitops-iac-flow)
4. [The Shared-VPC network design](#the-shared-vpc-network-design)
5. [Repository layout](#repository-layout)
6. [Walkthrough (screenshots)](#walkthrough-screenshots)
7. [Getting started](#getting-started)
8. [Security model](#security-model)

---

## Architecture

```
                                  ┌──────────────────────────────────────────────┐
  BAREMETAL (Rocky Linux)         │  Ubiquiti L2/L3 · VLAN trunks · mgmt network  │
  ┌──────────────┐  ┌──────────┐  └──────────────────────────────────────────────┘
  │ controller   │  │ compute  │                     ▲ provisioned + configured by
  │ (Keystone,   │  │ (nova,   │                     │
  │  neutron,    │  │  libvirt)│         ┌────────────┴─────────────┐
  │  glance,…)   │  │          │         │  Ansible (install/bring-up)│
  └──────────────┘  └──────────┘         │  Puppet  (config mgmt,     │
         ▲  OpenStack private cloud      │          roles/profiles +  │
         │                               │          Hiera)            │
         │  Terraform (OpenStack provider)└────────────────────────────┘
         │  reads clouds.yaml (Keystone application credential)
         │
  ┌──────┴───────────────── CONTROL PLANE (self-hosted, Ansible-provisioned) ─────────────┐
  │                                                                                        │
  │   GitLab ──(merge request)──▶ Atlantis ──terraform plan/apply──▶ OpenStack API         │
  │     │  · GitLab Runner                     │  · creds from Vault                       │
  │     │  · Dex + oauth2-proxy (SSO)          │  · clouds.yaml from Ansible template      │
  │     │                                      ▼                                           │
  │   Caddy (reverse proxy, TLS)          MinIO  ◀── terraform.tfstate (S3 backend)         │
  │                                       s3.mallards.io                                    │
  └────────────────────────────────────────────────────────────────────────────────────────┘
```

**Apply order:** `openstack-foundations` (projects, quotas, identity) → `openstack-networking`
(Shared-VPC networks, routers, firewall, RBAC). Each has its own state object in MinIO.

---

## The stack, layer by layer

| Layer | Tech | What it does |
|-------|------|--------------|
| **Physical network** | Ubiquiti (Ansible role `ubiquiti`) | VLAN trunks, mgmt network, L3 |
| **Baremetal OS** | Rocky Linux (`system_updates`) | Controller + compute hosts |
| **Private cloud** | OpenStack (Keystone, Nova, Neutron, Glance, Cinder) | The IaaS itself |
| **Cloud bring-up** | **Ansible** (`playbooks/openstack`) | Installs/bootstraps the OpenStack cluster |
| **Config management** | **Puppet** (roles/profiles + Hiera) | Ongoing host configuration, drift control |
| **Source + CI** | **GitLab** self-hosted (`gitlab`, `gitlab-runner`, `gitlab-bootstrap`) | Repos, merge requests, runners |
| **IaC automation** | **Atlantis** (`atlantis`) | Runs Terraform on merge requests |
| **State** | **MinIO** (`minio`) | S3-compatible backend for `terraform.tfstate` |
| **Secrets** | **Vault** (`atlantis/tasks/vault.yml`) | Injects MinIO + OpenStack creds at runtime |
| **Ingress / TLS** | **Caddy** (`caddy`) | Reverse proxy (e.g. `s3.mallards.io` → mgmt) |
| **SSO** | **Dex + oauth2-proxy** | Single sign-on to the control-plane services |
| **Cloud config** | **Terraform** (this repo) | Projects, quotas, identity, Shared-VPC network |

Everything above the baremetal line is **Ansible-provisioned**; the whole control plane is
reproducible from playbooks.

---

## The GitOps IaC flow

OpenStack configuration is **never applied by hand** — it flows through GitLab + Atlantis:

```
1. Engineer edits *.tf / *.tfvars on a branch, opens a Merge Request in GitLab
2. Atlantis auto-plans (webhook) and posts the `terraform plan` as an MR comment
3. Reviewer approves; the MR must be mergeable
4. Engineer comments `atlantis apply` → Atlantis runs `terraform apply`
        · OpenStack auth  ← clouds.yaml (Keystone application credential, templated by Ansible)
        · MinIO/S3 auth   ← AWS_ACCESS_KEY_ID/SECRET from Vault (never in code)
        · state written    → MinIO  (openstack/<config>/terraform.tfstate)
5. MR merges; the change is now the source of truth
```

- **`openstack-foundations`** — `automerge: true`, gated by the server-side Atlantis hook.
- **`openstack-networking`** — `apply_requirements: [approved, mergeable]`, manual merge.

This is the same "plan-in-PR, apply-on-comment, state-in-object-store" model used at scale on
GCP/AWS — implemented end-to-end on self-hosted infrastructure.

---

## The Shared-VPC network design

The Terraform models **GCP's Shared-VPC pattern on OpenStack**: dedicated **host projects** own
the networks/routers/firewalls and run *no compute*; **service projects** consume them via
Neutron **RBAC sharing** (`openstack_networking_rbac_policy_v2`).

```
HOST PROJECT  mall-network-<env>  (compute quota = 0)          SERVICE PROJECT  mall-k8s-<env>
  ├─ shared-<env>   (VLAN, provider segment) ──┐                 attaches ports to the shared /
  ├─ tenant-<env>   (self-service)             ├─ router-<env> ─▶  tenant networks, uses the
  └─ fw-<env>-{allow-internal,ssh,web,icmp} ───┘  (→ external)     fw-<env>-* SGs — all via RBAC
```

**Address plan** (host project per environment; `cloudops` is fully isolated — no RBAC in/out):

| Env | VLAN | Provider CIDR | Self-service CIDR | Host project | Consumer |
|-----|------|---------------|-------------------|--------------|----------|
| dev | 50 | 10.100.50.0/24 | 10.200.50.0/24 | `mall-network-dev` | `mall-k8s-dev` |
| stg | 51 | 10.100.51.0/24 | 10.200.51.0/24 | `mall-network-stg` | `mall-k8s-stg` |
| prod | 52 | 10.100.52.0/24 | 10.200.52.0/24 | `mall-network-prod` | `mall-k8s-prod` |
| cloudops | 53 | 10.100.53.0/24 | 10.200.53.0/24 | `mall-cloudops` | *(isolated)* |

Centralized, host-owned firewall groups (`allow-internal / ssh / web / icmp`) mirror an
enterprise security pattern — SSH is restricted to the trusted mgmt CIDR; internal traffic is
scoped to the provider + self-service ranges.

---

## Repository layout

```
knotapi-takehome-chaugh/
├── openstack-foundations/     # ROOT: projects, quotas, identity role bindings  (own MinIO state)
│   ├── projects.tf · identity.tf · providers.tf · backend.tf · variables.tf · outputs.tf
│   ├── atlantis.yaml          # automerge, autoplan
│   └── terraform.tfvars.example
├── openstack-networking/      # ROOT: Shared-VPC networks, routers, firewall, RBAC  (own MinIO state)
│   ├── networks.tf · firewall.tf · rbac.tf · locals.tf · data.tf · outputs.tf
│   ├── atlantis.yaml          # apply_requirements: [approved, mergeable]
│   └── terraform.tfvars.example
├── modules/                   # reusable modules (sourced locally here; versioned in GitLab in prod)
│   ├── project/               # openstack_identity_project_v3 + Nova/Neutron/Cinder quotas
│   ├── network/               # network + subnets + optional router (caller-managed for SVPC)
│   ├── security-group/        # security group + rules
│   ├── compute-instance/      # instance (image or volume boot, multi-NIC)
│   └── keypair/               # import or generate SSH keypair
├── docs/images/               # screenshots (see walkthrough)
└── .gitignore                 # blocks tfstate / *.tfvars / clouds.yaml / keys from ever committing
```

> **Note on module sources:** in this shared monorepo the roots reference modules by local path
> (`../modules/project`). In the live platform each module is a versioned GitLab repo
> (`git::…/openstack-modules/…?ref=<tag>`); the monorepo form is chosen so a reviewer can clone
> and read the whole system at once.

---

## Walkthrough (screenshots)

The end-to-end proof: start from an **empty** OpenStack, build everything through **GitLab merge
requests + Atlantis**, and watch the Shared-VPC topology and both statefiles come into existence.

### Part 1 — The empty starting point

Signed into a freshly-built OpenStack with **no projects and no tenant networking** — only the
admin-managed `external` network exists.

| | |
|---|---|
| ![OpenStack login](docs/images/01-openstack-login.png) | ![Projects: empty](docs/images/02-openstack-projects-empty.png) |
| *OpenStack Horizon login (`mallards-io` domain)* | *Identity → Projects: "No items to display"* |
| ![Network: empty](docs/images/03-openstack-network-empty.png) | ![Security groups: default only](docs/images/04-openstack-secgroups-empty.png) |
| *Network topology: just `external` (10.100.40.0/24)* | *Only the built-in `default` security group* |

### Part 2 — The self-hosted control plane

The GitOps toolchain, all Ansible-provisioned on baremetal.

| | |
|---|---|
| ![GitLab login](docs/images/05-gitlab-login.png) | ![GitLab groups](docs/images/06-gitlab-groups.png) |
| *Self-hosted GitLab CE (AD-backed sign-in)* | *`Cloud Engineering` → `OpenStack Live` (roots) + `OpenStack Modules`* |
| ![Atlantis](docs/images/07-atlantis-dashboard.png) | ![MinIO](docs/images/08-minio-state-store.png) |
| *Atlantis — apply enabled, job history per repo* | *MinIO `mallards-tfstate` bucket (S3 state backend)* |

### Part 3 — Foundations via GitOps (projects, quotas, identity)

Open an MR → GitLab CI lints (`fmt`) → **Atlantis plans** → approve → **`atlantis apply`** →
7 projects created → state written to MinIO.

| | |
|---|---|
| ![Foundations MR pipeline](docs/images/09-foundations-mr-pipeline.png) | ![Pipeline detail](docs/images/10-foundations-pipeline-detail.png) |
| *MR pipeline #13 — passed* | *`lint: fmt` + `external: atlantis/plan` + pre-workflow approval hook* |
| ![Atlantis plan (MR)](docs/images/11-foundations-atlantis-plan-mr.png) | ![Atlantis plan (job)](docs/images/12-foundations-atlantis-plan-job.png) |
| *Plan posted back to the MR* | *`Plan: 39 to add` — the 7 `project_ids` outputs* |
| ![Apply comment](docs/images/13-foundations-apply-comment.png) | ![Apply — role bindings](docs/images/14-foundations-apply-roles.png) |
| *Approved, then `atlantis apply -p foundations`* | *AD group → `admin` role bindings per project* |
| ![Apply complete](docs/images/15-foundations-apply-complete.png) | ![Projects created](docs/images/16-openstack-projects-created.png) |
| *`Apply complete! 39 added` + `project_ids`* | *7 projects now in OpenStack (host + k8s + cloudops)* |

![Foundations state in MinIO](docs/images/17-minio-foundations-state.png)
*`openstack/foundations/terraform.tfstate` now in MinIO (47.9 KiB).*

### Part 4 — Networking via GitOps (the Shared-VPC)

Same flow for the networking root — and the result shows the **SVPC pattern**: host-owned
networks/routers/firewalls **RBAC-shared** into the k8s service projects, with `cloudops`
deliberately **isolated**.

| | |
|---|---|
| ![Networking MR pipeline](docs/images/18-networking-mr-pipeline.png) | ![Pipeline detail](docs/images/19-networking-pipeline-detail.png) |
| *MR pipeline #15 — passed* | *`lint: fmt` + `atlantis/plan: networking`* |
| ![Atlantis plan (MR)](docs/images/20-networking-atlantis-plan-mr.png) | ![Atlantis plan (job)](docs/images/21-networking-atlantis-plan-job.png) |
| *Plan: subnets, e.g. `tenant-subnet-stg` 10.200.51.0/24* | *`Plan: 86 to add`* |
| ![Networking apply (MR)](docs/images/22-networking-apply-mr.png) | ![Apply complete](docs/images/23-networking-apply-complete.png) |
| *RBAC policies + router interfaces creating* | *`86 added` + `firewall_sg_ids` per env* |

**The Shared-VPC result:**

| | |
|---|---|
| ![CloudOps topology](docs/images/24-openstack-topology-svpc.png) | ![CloudOps networks](docs/images/25-openstack-networks-cloudops.png) |
| *`mall-cloudops`: external + shared + tenant, one router* | *shared (10.100.53.0/24) + tenant (10.200.53.0/24)* |
| ![CloudOps firewall SGs](docs/images/26-openstack-secgroups-cloudops.png) | ![k8s project sees shared nets](docs/images/27-openstack-networks-k8s-svpc-shared.png) |
| *Centralized `fw-cloudops-allow-{icmp,internal,ssh,web}`* | ***`mall-k8s-dev` sees `shared-dev`/`tenant-dev` via RBAC** — the SVPC payoff* |

![Networking state in MinIO](docs/images/28-minio-networking-state.png)
*`openstack/networking/terraform.tfstate` now in MinIO (117.5 KiB) — both roots have independent state.*

---

## Getting started

**Prerequisites:** an OpenStack cloud, a `clouds.yaml` with a Keystone **application credential**,
a MinIO (or any S3) bucket for state, and Atlantis wired to your GitLab.

```bash
# 1. Provide real values (kept local; git-ignored)
cp openstack-foundations/terraform.tfvars.example openstack-foundations/terraform.tfvars
cp openstack-networking/terraform.tfvars.example  openstack-networking/terraform.tfvars
#    → set REPLACE_WITH_YOUR_KEYSTONE_DOMAIN_ID, CIDRs, project names, etc.

# 2. Export backend + provider creds (Atlantis does this from Vault in the live flow)
export OS_CLOUD=<your-app-cred>
export AWS_ACCESS_KEY_ID=<minio-key>  AWS_SECRET_ACCESS_KEY=<minio-secret>

# 3. Apply foundations, then networking
cd openstack-foundations && terraform init && terraform apply
cd ../openstack-networking && terraform init && terraform apply
```

In normal operation you don't run these locally — you open a merge request and let Atlantis plan
and apply.

---

## Security model

- **No credentials in the repo.** OpenStack auth is a Keystone **application credential** via
  `clouds.yaml` (external); MinIO/S3 creds come from **Vault**, injected by Atlantis at runtime.
  Neither is ever committed.
- **`.gitignore`** blocks `*.tfstate*` (plaintext secrets), all `*.tfvars` (only `*.example`
  templates are tracked), `clouds.yaml`, and any keys.
- **Least privilege:** the application credential is scoped; host projects run no compute; SSH is
  restricted to the trusted mgmt CIDR; `cloudops` is network-isolated (no RBAC).
- **Auditable changes:** every OpenStack change is a reviewed, planned, applied merge request —
  no manual drift.
