module "cloudflare" {
  source                = "../../modules/cloudflare"
  cloudflare_token      = var.cloudflare_token
  cloudflare_zone_id    = var.cloudflare_zone_id
  cloudflare_account_id = var.cloudflare_account_id
  domain                = "vennpham.work"
  tunnel_id             = "aa3d250f-e275-4674-a1a3-9bcfe666286a"

  # Manage both DNS and Application Routes
  manage_tunnel_config = true
  enable_k8s_agent     = false

  # Application Routes (Ingress Rules)
  ingress_rules = [
    {
      hostname = "argocd.vennpham.work"
      service  = "http://192.168.122.201"
    },
    {
      hostname = "immich.vennpham.work"
      service  = "http://192.168.1.223:2283"
    },
    {
      hostname = "minio.vennpham.work"
      service  = "http://192.168.1.223:9001"
    },
    {
      hostname = "homecamera.vennpham.work"
      service  = "http://192.168.1.223:3000"
    }
  ]

  dns_records = {
    "argocd" = {
      type  = "CNAME"
      value = "aa3d250f-e275-4674-a1a3-9bcfe666286a.cfargotunnel.com"
    }
    "immich" = {
      type  = "CNAME"
      value = "aa3d250f-e275-4674-a1a3-9bcfe666286a.cfargotunnel.com"
    }
    "minio" = {
      type  = "CNAME"
      value = "aa3d250f-e275-4674-a1a3-9bcfe666286a.cfargotunnel.com"
    }
    "homecamera" = {
      type  = "CNAME"
      value = "aa3d250f-e275-4674-a1a3-9bcfe666286a.cfargotunnel.com"
    }
  }
}
