module "k8s_add_ons" {
  source = "../../modules/k8s-add-ons"

  argocd_admin_password = var.argocd_admin_password
}
