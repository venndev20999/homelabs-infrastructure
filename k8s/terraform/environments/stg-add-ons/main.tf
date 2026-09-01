locals {
  argocd_users  = yamldecode(file("${path.module}/../../../argocd-users.yaml"))
  grafana_users = yamldecode(file("${path.module}/../../../github-users.yaml"))
}

module "k8s_add_ons" {
  source = "../../modules/k8s-add-ons"

  kubeconfig_path       = var.kubeconfig_path
  argocd_admin_password = var.argocd_admin_password
  github_client_id      = var.github_client_id
  github_client_secret  = var.github_client_secret
  admin_users           = local.argocd_users.admin
  developer_users       = local.argocd_users.developer
  sops_age_key          = var.sops_age_key
}

module "k8s_monitoring" {
  count  = var.enable_k8s_monitoring ? 1 : 0
  source = "../../modules/k8s-monitoring"

  minio_endpoint                 = var.minio_endpoint
  minio_user                     = var.minio_user
  minio_password                 = var.minio_password
  grafana_github_client_id       = var.grafana_github_client_id
  grafana_github_client_secret   = var.grafana_github_client_secret
  grafana_github_admin_users     = local.grafana_users.admin
  grafana_github_developer_users = local.grafana_users.developer
}

# ── ClickStack Observability Module (ClickHouse, HyperDX, OTel) ────────────────
module "clickstack" {
  count  = var.enable_clickstack ? 1 : 0
  source = "../../modules/clickstack"

  clickhouse_node     = "talos-vm-worker-4-stg"
  clickhouse_pvc_size = "50Gi"
  storage_class_name  = "local-path"
  frontend_url        = var.clickstack_frontend_url
  app_user_password   = var.clickstack_app_password
  otel_user_password  = var.clickstack_otel_password
  hyperdx_api_key     = var.clickstack_hyperdx_api_key
  mongodb_password    = var.clickstack_mongodb_password
}

# ── Import Blocks for Pre-existing Namespaces ──────────────────────────────────
# This allows Terraform to safely import and manage the lifecycle of these namespaces
# rather than returning "already exists" errors when trying to create them.
import {
  to = module.k8s_add_ons.kubernetes_namespace_v1.argocd
  id = "argocd"
}

import {
  to = module.k8s_add_ons.kubernetes_namespace_v1.envoy_gateway_system
  id = "envoy-gateway-system"
}

import {
  to = module.k8s_add_ons.kubernetes_namespace_v1.metallb_system
  id = "metallb-system"
}

# (Commented while enable_k8s_monitoring is false to prevent import target errors)
# import {
#   to = module.k8s_monitoring[0].kubernetes_namespace_v1.monitoring
#   id = "monitoring"
# }

# ── Import Blocks for Pre-existing Helm Releases ───────────────────────────────
# This instructs Terraform to adopt the existing Helm releases inside the cluster
# rather than throwing "cannot re-use a name that is still in use" errors.
import {
  to = module.k8s_add_ons.helm_release.argocd
  id = "argocd/argocd"
}

import {
  to = module.k8s_add_ons.helm_release.envoy_gateway
  id = "envoy-gateway-system/envoy-gateway"
}

import {
  to = module.k8s_add_ons.helm_release.metallb
  id = "metallb-system/metallb"
}

# (Commented while enable_k8s_monitoring is false to prevent import target errors)
# import {
#   to = module.k8s_monitoring[0].helm_release.loki
#   id = "monitoring/loki"
# }
# 
# import {
#   to = module.k8s_monitoring[0].helm_release.tempo
#   id = "monitoring/tempo"
# }
# 
# import {
#   to = module.k8s_monitoring[0].helm_release.prometheus
#   id = "monitoring/prometheus"
# }

