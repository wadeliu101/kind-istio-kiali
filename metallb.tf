data "external" "subnet" {
  program = ["/bin/bash", "-c", "docker network inspect -f '{{json .IPAM.Config}}' kind | jq .[0]"]

  depends_on = [ kind_cluster.istio-kiali ]
}

resource "null_resource" "installing_metallb_using_default_manifests" {
  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml"
  }
  
  provisioner "local-exec" {
    command = "kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey=\"$(openssl rand -base64 128)\""
  }
  
  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml"
  }

  provisioner "local-exec" {
    command = "kubectl wait deployment --all --timeout=-1s --for=condition=Available -n metallb-system"
  }

  depends_on = [ kind_cluster.istio-kiali ]
}

resource "kubernetes_config_map" "metallb-config" {
  metadata {
    name      = "config"
    namespace = "metallb-system"
  }

  # data = {
  #   config = "address-pools:\n- name: default\n  protocol: layer2\n  addresses:\n  - ${cidrhost(data.external.subnet.result.Subnet, 200)}-${cidrhost(data.external.subnet.result.Subnet, 250)}\n"
  # }
  data = {
    config = "address-pools:\n- name: default\n  protocol: layer2\n  addresses:\n  - 127.0.0.1-127.0.0.1\n"
  }

  depends_on = [ null_resource.installing_metallb_using_default_manifests ]
}