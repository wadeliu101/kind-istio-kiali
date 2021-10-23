resource "helm_release" "kiali-operator" {
  name       = "kiali-operator"
  repository = "https://kiali.org/helm-charts"
  chart      = "kiali-operator"
  version    = var.KIALI_VERSION
  namespace  = "kiali-operator"
  create_namespace = true
  depends_on = [
    time_sleep.wait_istio_ready,
    helm_release.prometheus-operator,
    helm_release.jaeger-operator
  ]
}
resource "local_file" "kiali" {
  content  = <<-EOF
  apiVersion: kiali.io/v1alpha1
  kind: Kiali
  metadata:
    name: kiali
    annotations:
      ansible.operator-sdk/verbosity: "1"
  spec:
    deployment:
      accessible_namespaces:
      - "**"
      ingress_enabled: false
      namespace: istio-system
    auth:
      strategy: "anonymous"
    external_services:
      istio:
        config_map_name: "istio"
        istiod_deployment_name: "istiod"
        istio_sidecar_injector_config_map_name: "istio-sidecar-injector"
      prometheus:
        url: "http://prometheus-operator-kube-p-prometheus.kube-mon:9090"
      grafana:
        in_cluster_url: http://prometheus-operator-grafana.kube-mon
        url: http://prometheus-operator-grafana.kube-mon
        auth:
          password: 'prom-operator'
          username: 'admin'
      tracing:
        in_cluster_url: http://jaeger-operator-jaeger-query.istio-system:16685
  ---
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
      - "*"
  ---
  apiVersion: networking.istio.io/v1alpha3
  kind: VirtualService
  metadata:
    name: kiali
  spec:
    hosts:
    - "*"
    gateways:
    - kiali
    http:
    - route:
      - destination:
          host: kiali
          port:
            number: 20001
  EOF
  filename = "${path.root}/configs/kiali.yaml"
  provisioner "local-exec" {
    command = "kubectl apply -f ${self.filename} -n ${kubernetes_namespace.istio-system.metadata[0].name}"
  }
  depends_on = [
    helm_release.kiali-operator
  ]
}
