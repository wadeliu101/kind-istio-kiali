resource "helm_release" "kiali-operator" {
  name       = "kiali-operator"

  repository = "https://kiali.org/helm-charts"
  chart      = "kiali-operator"
  version    = "1.31.0"
  namespace  = "kiali-operator"

  create_namespace = true

  depends_on = [ null_resource.installing-istio, helm_release.prometheus-operator, helm_release.jaeger-operator ]
}

resource "null_resource" "installing-kiali" {
  provisioner "local-exec" {
    command = "kubectl apply -f ./kiali.yaml -n istio-system"
  }

  provisioner "local-exec" {
    when = destroy
    command = "kubectl delete -f ./kiali.yaml -n istio-system"
  }

  depends_on = [ helm_release.kiali-operator ]
}