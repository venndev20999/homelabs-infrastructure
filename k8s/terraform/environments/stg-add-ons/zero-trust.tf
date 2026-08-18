
# Instantiate the Tailscale Subnet Router module for VPN/Zero-Trust Access
module "tailscale" {
  source = "../../modules/k8s-zero-trust"

  tailscale_auth_key = var.tailscale_auth_key
  advertise_routes = [
    "192.168.122.0/24", // External VM NAT/Staging subnet
    "192.168.1.0/24",   // Home subnet
    "10.244.0.0/16",    // Kubernetes Pod CIDR
    "10.96.0.0/12"      // Kubernetes Service CIDR
  ]
}
