resource "null_resource" "download_istio" {
  triggers = {
    ISTIO_VERSION = var.ISTIO_VERSION
  }
  provisioner "local-exec" {
    command = "curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${self.triggers.ISTIO_VERSION} sh -"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -r ${path.root}/istio-${self.triggers.ISTIO_VERSION}"
  }
  depends_on = [
    helm_release.metallb
  ]
}
resource "kubernetes_namespace" "istio-operator" {
  metadata {
    annotations = {
      name                             = "istio-operator"
      "meta.helm.sh/release-name"      = "istio-operator"
      "meta.helm.sh/release-namespace" = "istio-operator"
    }
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
    name = "istio-operator"
  }
  depends_on = [null_resource.download_istio]
}
resource "helm_release" "istio-operator" {
  name            = "istio-operator"
  repository      = "${path.root}/istio-${var.ISTIO_VERSION}/manifests/charts"
  chart           = "istio-operator"
  namespace       = kubernetes_namespace.istio-operator.metadata[0].name
  cleanup_on_fail = true
}
resource "kubernetes_namespace" "istio-system" {
  metadata {
    annotations = {
      name = "istio-system"
    }
    name = "istio-system"
  }
  depends_on = [helm_release.istio-operator]
}
resource "local_file" "istio-profile" {
  content  = <<-EOF
  apiVersion: install.istio.io/v1alpha1
  kind: IstioOperator
  metadata:
    name: istiocontrolplane
  spec:
    profile: demo
    components:
      ingressGateways:
      - name: istio-ingressgateway
        enabled: true
        k8s:
          service:
            ports:
            - name: status-port
              nodePort: 31151
              port: 15021
              protocol: TCP
              targetPort: 15021
            - name: http2
              nodePort: 32041
              port: 80
              protocol: TCP
              targetPort: 8080
            - name: https
              nodePort: 31236
              port: 443
              protocol: TCP
              targetPort: 8443
            - name: tcp
              nodePort: 31705
              port: 31400
              protocol: TCP
              targetPort: 31400
            - name: tls
              nodePort: 32152
              port: 15443
              protocol: TCP
              targetPort: 15443
          nodeSelector:
            ingress-ready: "true"
          tolerations:
          - key: "node-role.kubernetes.io/master"
            operator: "Exists"
            effect: "NoSchedule"
      egressGateways:
      - name: istio-egressgateway
        enabled: true
        k8s:
          nodeSelector:
            ingress-ready: "true"
          tolerations:
          - key: "node-role.kubernetes.io/master"
            operator: "Exists"
            effect: "NoSchedule"
  EOF
  filename = "${path.root}/configs/istio-profile.yaml"
  provisioner "local-exec" {
    command = "kubectl apply -f ${self.filename} -n ${kubernetes_namespace.istio-system.metadata[0].name}"
  }
  depends_on = [
    helm_release.istio-operator
  ]
}
resource "time_sleep" "wait_istio_ready" {
  create_duration = "30s"
  provisioner "local-exec" {
    command = "kubectl wait --for=condition=ready pods -l release=istio -n ${kubernetes_namespace.istio-system.metadata[0].name}"
  }
  depends_on = [
    local_file.istio-profile
  ]
}
data "kubernetes_service" "istio-ingressgateway" {
  metadata {
    name = "istio-ingressgateway"
    namespace = kubernetes_namespace.istio-system.metadata[0].name
  }
  depends_on = [
    time_sleep.wait_istio_ready
  ]
}
