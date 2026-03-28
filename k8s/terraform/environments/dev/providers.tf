terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14.0"
    }
  }
}

provider "talos" {}

provider "helm" {
  kubernetes {
    host                   = module.talos_cluster.kubeconfig_host
    client_certificate     = base64decode(module.talos_cluster.kubeconfig_client_cert)
    client_key             = base64decode(module.talos_cluster.kubeconfig_client_key)
    cluster_ca_certificate = base64decode(module.talos_cluster.kubeconfig_ca_cert)
  }
}
