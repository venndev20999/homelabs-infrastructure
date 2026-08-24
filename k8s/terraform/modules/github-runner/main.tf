# Create Namespace for the Controller
resource "kubernetes_namespace_v1" "controller" {
  metadata {
    name = var.controller_namespace
  }
}

# Create Namespace for the Runner Scale Set
resource "kubernetes_namespace_v1" "runner" {
  metadata {
    name = var.namespace
  }
}

# Secret containing the GitHub PAT token
resource "kubernetes_secret_v1" "github_token" {
  metadata {
    name      = "github-runner-token"
    namespace = kubernetes_namespace_v1.runner.metadata[0].name
  }

  data = {
    github_token = var.github_token
  }

  type = "Opaque"
}

# Deploy Actions Runner Controller (ARC) Manager
resource "helm_release" "controller" {
  depends_on = [
    kubernetes_namespace_v1.controller
  ]

  name       = "arc"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set-controller"
  version    = "0.9.3"
  namespace  = kubernetes_namespace_v1.controller.metadata[0].name
}

# Deploy GitHub Actions Runner Scale Set
resource "helm_release" "runner_set" {
  depends_on = [
    helm_release.controller,
    kubernetes_secret_v1.github_token
  ]

  name       = "arc-runner-set"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set"
  version    = "0.9.3"
  namespace  = kubernetes_namespace_v1.runner.metadata[0].name

  values = [
    yamlencode({
      githubConfigUrl    = var.github_url
      githubConfigSecret = kubernetes_secret_v1.github_token.metadata[0].name
      runnerScaleSetName = "staging-runner"

      template = {
        spec = {
          # Pin runner pods to worker-4 to protect the rest of the cluster
          nodeSelector = {
            "kubernetes.io/hostname" = var.runner_node_name
          }
          containers = [
            {
              name  = "runner"
              image = "ghcr.io/actions/actions-runner:latest"
              # Request 16GB RAM and 2 vCPUs for Rails builds
              resources = {
                requests = {
                  cpu    = "2"
                  memory = "16Gi"
                }
                limits = {
                  cpu    = "2"
                  memory = "16Gi"
                }
              }
            }
          ]
        }
      }
    })
  ]
}
