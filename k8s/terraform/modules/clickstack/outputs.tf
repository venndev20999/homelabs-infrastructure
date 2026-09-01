output "namespace" {
  description = "Namespace where ClickStack is deployed"
  value       = kubernetes_namespace_v1.clickstack.metadata[0].name
}

output "clickhouse_http_endpoint" {
  description = "ClickHouse HTTP query endpoint"
  value       = "http://clickstack-clickhouse.${kubernetes_namespace_v1.clickstack.metadata[0].name}.svc.cluster.local:8123"
}

output "clickhouse_tcp_endpoint" {
  description = "ClickHouse Native TCP client endpoint"
  value       = "clickstack-clickhouse.${kubernetes_namespace_v1.clickstack.metadata[0].name}.svc.cluster.local:9000"
}

output "hyperdx_ui_endpoint" {
  description = "HyperDX Web UI Service internal endpoint"
  value       = "http://clickstack-app.${kubernetes_namespace_v1.clickstack.metadata[0].name}.svc.cluster.local:3000"
}

output "otel_collector_grpc_endpoint" {
  description = "OpenTelemetry Collector OTLP gRPC endpoint"
  value       = "clickstack-otel-collector.${kubernetes_namespace_v1.clickstack.metadata[0].name}.svc.cluster.local:4317"
}

output "otel_collector_http_endpoint" {
  description = "OpenTelemetry Collector OTLP HTTP endpoint"
  value       = "http://clickstack-otel-collector.${kubernetes_namespace_v1.clickstack.metadata[0].name}.svc.cluster.local:4318"
}
