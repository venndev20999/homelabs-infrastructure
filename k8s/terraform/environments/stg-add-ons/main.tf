module "k8s_add_ons" {
  source = "../../modules/k8s-add-ons"

  kubeconfig_path       = var.kubeconfig_path
  argocd_admin_password = var.argocd_admin_password
}
