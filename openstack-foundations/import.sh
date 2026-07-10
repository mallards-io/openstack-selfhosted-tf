#!/usr/bin/env bash
# Adopt the existing (puppet-created) projects + quotas into Terraform state so
# `terraform apply` RECONCILES them instead of trying to recreate (which would
# 409 on the duplicate project name). Role assignments are idempotent at the API
# and do NOT need import — apply reconciles them.
#
# Run on a host with the openstack CLI + admin credentials (e.g. the controller,
# `. /root/admin-openrc`), AFTER `terraform init`, from this repo directory.
# It PRINTS the import commands — review them, then execute:
#
#     ./import.sh | bash
#
# Requires bash 4+ (associative arrays) — fine on the Linux controller/mgmt.
set -euo pipefail

DOMAIN="mallards-io"

# project name -> has a cinder (storage) quota resource
declare -A PROJECTS=(
  [mall-network-dev]=no
  [mall-network-stg]=no
  [mall-network-prod]=no
  [mall-k8s-dev]=yes
  [mall-k8s-stg]=yes
  [mall-k8s-prod]=yes
  [mall-cloudops]=yes
)

for name in "${!PROJECTS[@]}"; do
  id=$(openstack project show "$name" --domain "$DOMAIN" -f value -c id 2>/dev/null || true)
  if [ -z "$id" ]; then
    echo "# WARN: project $name not found in domain $DOMAIN — skipping" >&2
    continue
  fi
  echo "terraform import 'module.project[\"$name\"].openstack_identity_project_v3.this' $id"
  echo "terraform import 'module.project[\"$name\"].openstack_compute_quotaset_v2.this[0]' $id"
  echo "terraform import 'module.project[\"$name\"].openstack_networking_quota_v2.this[0]' $id"
  if [ "${PROJECTS[$name]}" = "yes" ]; then
    echo "terraform import 'module.project[\"$name\"].openstack_blockstorage_quotaset_v3.this[0]' $id"
  fi
done
