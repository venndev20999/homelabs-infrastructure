terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = ">= 0.6.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.14.0"
    }
  }
}
