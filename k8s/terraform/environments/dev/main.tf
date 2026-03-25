module "talos_cluster" {
  source = "../../modules/talos-cluster"

  cluster_name     = "finance-stock-dev-k8s"
  cluster_endpoint = "https://10.0.0.10:6443"

  # Dynamic number of masters and workers: you scale the cluster simply by adding or removing IPs from these lists.
  controlplane_ips = ["10.0.0.10"]
  worker_ips       = [
    "10.0.0.11",
    "10.0.0.12",
    "10.0.0.13",
    "10.0.0.14",
    "10.0.0.15"
  ]

  talos_version    = "v1.7.0"
}
