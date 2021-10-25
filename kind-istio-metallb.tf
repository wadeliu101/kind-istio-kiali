module "kind-istio-metallb" {
  source          = "git@github.com:GrassShrimp/kind-istio-metallb.git"
  ISTIO_VERSION   = var.ISTIO_VERSION
  KIND_VERSION    = var.KIND_VERSION
  METALLB_VERSION = var.METALLB_VERSION
  KIND_CONFIG     = <<-EOF
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    nodes:
    - role: control-plane
      kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
      extraPortMappings:
      - containerPort: 32041
        hostPort: 80
        protocol: TCP
      - containerPort: 31236
        hostPort: 443
        protocol: TCP
    - role: worker
    - role: worker
  EOF
  ISTIO_PROFILE   = <<-EOF
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
}
