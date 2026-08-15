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

  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "k8s/stg/terraform.tfstate"
    region                      = "main"
    endpoint                    = "http://192.168.1.223:9000"
    access_key                  = "vennpham"
    secret_key                  = "dnquynh#123"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    force_path_style            = true
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

provider "kubernetes" {
  host                   = module.talos_cluster.kubeconfig_host
  client_certificate     = base64decode(module.talos_cluster.kubeconfig_client_cert)
  client_key             = base64decode(module.talos_cluster.kubeconfig_client_key)
  cluster_ca_certificate = base64decode(module.talos_cluster.kubeconfig_ca_cert)
}
