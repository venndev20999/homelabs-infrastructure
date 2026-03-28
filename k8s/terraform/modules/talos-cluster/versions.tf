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
  }
}
