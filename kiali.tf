resource "kubernetes_namespace" "kiali" {
  metadata {
    name = "kiali"
  }
  depends_on = [
    module.kind-istio-metallb,
    helm_release.prometheus-operator,
    helm_release.jaeger-operator
  ]
}
resource "helm_release" "kiali-operator" {
  name       = "kiali-operator"
  repository = "https://kiali.org/helm-charts"
  chart      = "kiali-operator"
  version    = var.KIALI_VERSION
  namespace  = "kiali-operator"
  create_namespace = true
  values = [
    <<-EOF
    clusterRoleCreator: true
    cr:
      create: true
      namespace: ${kubernetes_namespace.kiali.metadata[0].name}
      spec:
        auth:
          strategy: "anonymous"
        deployment:
          accessible_namespaces: 
          - "**"
          ingress_enabled: false
        istio_namespace: istio-system
        external_services:
          prometheus:
            url: "http://prometheus-operator-kube-p-prometheus.${helm_release.prometheus-operator.namespace}:9090"
          grafana:
            in_cluster_url: http://prometheus-operator-grafana.${helm_release.prometheus-operator.namespace}
            url: http://prometheus-operator-grafana.${helm_release.prometheus-operator.namespace}
            auth:
              password: "admin"
              username: "admin"
              type: "basic"
          tracing:
            in_cluster_url: http://jaeger-operator-jaeger-query.${kubernetes_namespace.jaeger.metadata[0].name}:16685
    EOF
  ]
}
resource "local_file" "kiali-router" {
  content  = <<-EOF
  apiVersion: networking.istio.io/v1alpha3
  kind: Gateway
  metadata:
    name: kiali
  spec:
    selector:
      istio: ingressgateway
    servers:
    - port:
        number: 80
        name: http
        protocol: HTTP
      hosts:
      - "kiali.${module.kind-istio-metallb.ingress_ip_address}.nip.io"
  ---
  apiVersion: networking.istio.io/v1alpha3
  kind: VirtualService
  metadata:
    name: kiali
  spec:
    hosts:
    - "kiali.${module.kind-istio-metallb.ingress_ip_address}.nip.io"
    gateways:
    - kiali
    http:
    - route:
      - destination:
          host: kiali.${kubernetes_namespace.kiali.metadata[0].name}.svc.cluster.local
          port:
            number: 20001
  EOF
  filename = "${path.root}/configs/kiali.yaml"
  provisioner "local-exec" {
    command = "kubectl apply -f ${self.filename} -n ${kubernetes_namespace.kiali.metadata[0].name}"
  }
  depends_on = [
    helm_release.kiali-operator
  ]
}
