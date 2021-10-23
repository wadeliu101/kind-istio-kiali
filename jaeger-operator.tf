resource "helm_release" "jaeger-operator" {
  name              = "jaeger-operator"
  repository        = "https://jaegertracing.github.io/helm-charts" 
  chart             = "jaeger-operator"
  version           = var.JAEGER_VERSION
  namespace         = "jaeger-operator"
  values = [
  <<EOF
  rbac:
    clusterRole: true
  jaeger:
    create: true
    namespace: istio-system
  EOF
  ]
  create_namespace  = true
  depends_on = [
    time_sleep.wait_istio_ready
  ]
}
