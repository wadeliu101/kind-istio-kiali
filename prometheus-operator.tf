resource "helm_release" "prometheus-operator" {
  name              = "prometheus-operator"
  repository        = "https://prometheus-community.github.io/helm-charts" 
  chart             = "kube-prometheus-stack"
  version           = var.PROMETHEUS_VERSION
  namespace         = "kube-mon"
  values = [
  <<EOF
  prometheus:
    prometheusSpec:
      storageSpec:
        volumeClaimTemplate:
          spec:
            storageClassName: "standard"
            resources:
              requests:
                storage: 10Gi
      additionalScrapeConfigs:
      - job_name: 'istiod'
        kubernetes_sd_configs:
        - role: endpoints
          namespaces:
            names:
            - istio-system
        relabel_configs:
        - source_labels: [__meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: istiod;http-monitoring
      - job_name: 'envoy-stats'
        metrics_path: /stats/prometheus
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - source_labels: [__meta_kubernetes_pod_container_port_name]
          action: keep
          regex: '.*-envoy-prom'
  alertmanager:
    enabled: false
  EOF
  ]
  create_namespace  = true
  depends_on = [
    time_sleep.wait_istio_ready
  ]
}