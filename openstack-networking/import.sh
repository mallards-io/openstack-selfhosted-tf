#!/usr/bin/env bash
# Networking adoption helper. Prints commands — review, then run selectively.
# Requires openstack CLI + admin creds (e.g. `. /root/admin-openrc`) and bash 4+.
#
#   PART A: import the existing per-env networks/subnets/routers into TF state so
#           `apply` reconciles them instead of recreating (they carry live ports).
#   PART B: delete the stale cloudops network+SG RBAC (from when cloudops was a
#           consumer of dev/stg/prod — now isolated).
#
# NOT covered here (finalize during a live `terraform plan`, together):
#   router interfaces, SG rules, and consumer RBAC policies — these conflict on
#   re-create, so either import them once `plan` shows their addresses, or (for a
#   near-empty homelab) let TF recreate the firewall/RBAC layer after deleting the
#   puppet-made copies. cloudops (env #4) is net-new and applies cleanly.
set -euo pipefail
DOMAIN="mallards-io"

echo "# ---- PART A: import existing dev/stg/prod networks/subnets/routers ----"
for env in dev stg prod; do
  for kind in shared tenant; do
    net=$(openstack network show "${kind}-${env}" -f value -c id 2>/dev/null || true)
    if [ -n "$net" ]; then
      echo "terraform import 'module.${kind}_net[\"${env}\"].openstack_networking_network_v2.this' ${net}"
      sub=$(openstack subnet show "${kind}-subnet-${env}" -f value -c id 2>/dev/null || true)
      [ -n "$sub" ] && echo "terraform import 'module.${kind}_net[\"${env}\"].openstack_networking_subnet_v2.this[0]' ${sub}"
    fi
  done
  r=$(openstack router show "router-${env}" -f value -c id 2>/dev/null || true)
  [ -n "$r" ] && echo "terraform import 'openstack_networking_router_v2.env[\"${env}\"]' ${r}"
done

echo "# ---- PART B: delete stale cloudops RBAC (make cloudops isolated) ----"
cloudops=$(openstack project show mall-cloudops --domain "$DOMAIN" -f value -c id 2>/dev/null || true)
if [ -n "$cloudops" ]; then
  openstack network rbac list -f value -c ID -c "Target Project" 2>/dev/null \
    | awk -v c="$cloudops" '$2==c {print "openstack network rbac delete "$1"  # stale cloudops share"}'
fi
