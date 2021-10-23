resource "null_resource" "bookinfo" {
  provisioner "local-exec" {
    command = "kubectl label namespace default istio-injection=enabled"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl label namespace default istio-injection-"
  }
  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo.yaml"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/platform/kube/bookinfo.yaml"
  }
  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/networking/bookinfo-gateway.yaml"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/networking/bookinfo-gateway.yaml"
  }
  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/networking/destination-rule-all.yaml"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.11/samples/bookinfo/networking/destination-rule-all.yaml"
  }
}
