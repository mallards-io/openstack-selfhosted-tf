# Derived logic only — the topology inputs live in var.environments / terraform.tfvars.
locals {
  fw_names = ["allow-internal", "allow-ssh", "allow-web", "allow-icmp"]

  # fw-<env>-<sg> -> its rule set (mirrors shared_vpc.pp).
  fw_rule_sets = merge([
    for env, cfg in var.environments : {
      "${env}:allow-internal" = [
        { direction = "ingress", remote_ip_prefix = cfg.provider_cidr },
        { direction = "ingress", remote_ip_prefix = cfg.selfservice_cidr },
      ]
      "${env}:allow-ssh" = [
        { direction = "ingress", protocol = "tcp", port_range_min = 22, port_range_max = 22, remote_ip_prefix = var.fw_mgmt_cidr },
      ]
      "${env}:allow-web" = [
        { direction = "ingress", protocol = "tcp", port_range_min = 80, port_range_max = 80, remote_ip_prefix = "0.0.0.0/0" },
        { direction = "ingress", protocol = "tcp", port_range_min = 443, port_range_max = 443, remote_ip_prefix = "0.0.0.0/0" },
      ]
      "${env}:allow-icmp" = [
        { direction = "ingress", protocol = "icmp", remote_ip_prefix = "0.0.0.0/0" },
      ]
    }
  ]...)

  # (env, sg) product -> firewall SG instances.
  fw_sgs = {
    for pair in setproduct(keys(var.environments), local.fw_names) :
    "${pair[0]}:${pair[1]}" => { env = pair[0], sg = pair[1] }
  }

  # Network RBAC: (env, consumer, net_type) — only for envs with consumers.
  net_rbac = {
    for item in flatten([
      for env, cfg in var.environments : [
        for consumer in cfg.consumers : [
          for t in ["shared", "tenant"] : {
            key = "${env}:${consumer}:${t}", env = env, consumer = consumer, type = t
          }
        ]
      ]
    ]) : item.key => item
  }

  # Firewall SG RBAC: (env, consumer, sg).
  fw_rbac = {
    for item in flatten([
      for env, cfg in var.environments : [
        for consumer in cfg.consumers : [
          for sg in local.fw_names : {
            key = "${env}:${consumer}:${sg}", env = env, consumer = consumer, sg = sg
          }
        ]
      ]
    ]) : item.key => item
  }

  consumers = toset(flatten([for cfg in var.environments : cfg.consumers]))
}
