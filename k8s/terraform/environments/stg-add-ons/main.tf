module "k8s_add_ons" {
  source = "../../modules/k8s-add-ons"

  kubeconfig_path       = var.kubeconfig_path
  argocd_admin_password = var.argocd_admin_password
}

module "k8s_monitoring" {
  source = "../../modules/k8s-monitoring"

  minio_endpoint = var.minio_endpoint
  minio_user     = var.minio_user
  minio_password = var.minio_password
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

import {
  to = module.k8s_monitoring.kubernetes_namespace_v1.monitoring
  id = "monitoring"
}

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

import {
  to = module.k8s_monitoring.helm_release.loki
  id = "monitoring/loki"
}

import {
  to = module.k8s_monitoring.helm_release.tempo
  id = "monitoring/tempo"
}

import {
  to = module.k8s_monitoring.helm_release.prometheus
  id = "monitoring/prometheus"
}
