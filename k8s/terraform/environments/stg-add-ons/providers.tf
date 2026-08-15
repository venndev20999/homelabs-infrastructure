terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
  }

  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "k8s/stg-add-ons/terraform.tfstate"
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

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}
