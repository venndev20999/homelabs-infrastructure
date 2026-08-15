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
