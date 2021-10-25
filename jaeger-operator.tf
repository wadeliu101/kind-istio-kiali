resource "kubernetes_namespace" "jaeger" {
  metadata {
    name = "jaeger"
  }
}
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
    namespace: ${kubernetes_namespace.jaeger.metadata[0].name}
    spec:
      ingress:
        enabled: false
  EOF
  ]
  create_namespace  = true
  depends_on = [
    module.kind-istio-metallb
  ]
}
