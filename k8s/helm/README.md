# Helm Charts — Finance Stock Platform

## Structure

```
helm/
├── apps/                        # Application Helm charts (one per microservice)
│   ├── market-api/              # Python FastAPI — market data + accumulation signals
│   ├── web-dashboard/           # Next.js — frontend dashboard
│   ├── ksqldb/                  # ksqlDB server
│   └── kafka-connect/           # Kafka Connect
│
├── infra/                       # Infrastructure dependency charts (DB, broker, cache)
│   ├── kafka/                   # Kafka cluster (via Strimzi or Bitnami)
│   ├── postgres/                # PostgreSQL
│   └── elasticsearch/           # Elasticsearch
│
├── environments/                # Per-env values overrides (ArgoCD ApplicationSets)
│   ├── dev/
│   │   ├── market-api.yaml
│   │   ├── web-dashboard.yaml
│   │   ├── ksqldb.yaml
│   │   └── kafka-connect.yaml
│   ├── staging/
│   │   └── ...
│   └── prod/
│       └── ...
│
└── argocd/                      # ArgoCD Application/ApplicationSet manifests
    ├── projects/
    │   └── finance-stock.yaml   # ArgoCD Project (RBAC boundary)
    ├── apps/                    # One Application per microservice
    │   ├── market-api.yaml
    │   ├── web-dashboard.yaml
    │   ├── ksqldb.yaml
    │   └── kafka-connect.yaml
    └── app-of-apps.yaml         # Root App-of-Apps (bootstraps everything)
```

## Deployment Flow

```
kubectl apply -f argocd/app-of-apps.yaml
       │
       └─► ArgoCD syncs argocd/apps/*.yaml
                  │
                  └─► Each App points to helm/apps/<service>
                             + values from helm/environments/<env>/<service>.yaml
```

## Adding a new microservice

1. `helm create helm/apps/<service-name>`
2. Edit `Chart.yaml`, `values.yaml`
3. Add `helm/environments/prod/<service-name>.yaml` with prod overrides
4. Add `helm/argocd/apps/<service-name>.yaml` ArgoCD Application manifest
