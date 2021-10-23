data "external" "subnet" {
  program = ["/bin/bash", "-c", "docker network inspect -f '{{json .IPAM.Config}}' kind | jq .[0]"]
  depends_on = [
    kind_cluster.k8s-cluster
  ]
}
resource "helm_release" "metallb" {
  name             = "metallb"
  repository       = "https://metallb.github.io/metallb"
  chart            = "metallb"
  namespace        = "metallb"
  version          = var.METALLB_VERSION
  create_namespace = true
  values = [
    <<-EOF
  configInline:
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      # - ${cidrhost(data.external.subnet.result.Subnet, 150)}-${cidrhost(data.external.subnet.result.Subnet, 200)}
      # for mac
      - 127.0.0.1 - 127.0.0.1
  EOF
  ]
  depends_on = [
    kind_cluster.k8s-cluster
  ]
}
