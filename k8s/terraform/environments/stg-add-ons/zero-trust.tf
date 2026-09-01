
# Secret containing the Tailscale Auth Key in namespace vpn for the ArgoCD zero-trust application
resource "kubernetes_secret_v1" "tailscale_auth" {
  metadata {
    name      = "tailscale-auth"
    namespace = "vpn"
  }

  data = {
    TS_AUTHKEY = var.tailscale_auth_key
  }

  type = "Opaque"
}

import {
  to = kubernetes_secret_v1.tailscale_auth
  id = "vpn/tailscale-auth"
}


