resource "kind_cluster" "istio-kiali" {
  name = "istio-kiali"
  node_image = "kindest/node:v1.20.2@sha256:8f7ea6e7642c0da54f04a7ee10431549c0257315b3a634f6ef2fecaaedb19bab"
  kind_config = <<KIONF
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
  KIONF
  wait_for_ready = true

  provisioner "local-exec" {
    when    = destroy
    command = "rm ${self.kubeconfig_path}"
  }
}