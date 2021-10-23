# kind-istio-kiali

This is demo for display dashboard of kiali

## Prerequisites

- [terraform](https://www.terraform.io/downloads.html)
- [docker](https://www.docker.com/products/docker-desktop) or [podman](https://podman.io/getting-started/installation)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [helm](https://helm.sh/docs/intro/install/)

## Usage

initialize terraform module

```bash
$ terraform init
```

set up enviroment on kind cluster, include istio, prometheus, grafana, jaeger, and kiali

```bash
$ terraform apply -auto-approve
```

for destroy

```bash
$ terraform destroy -auto-approve
```

![kiali-graph01](https://github.com/GrassShrimp/kind-istio-kiali/blob/master/kiali-graph01.png)
![kiali-graph02](https://github.com/GrassShrimp/kind-istio-kiali/blob/master/kiali-graph02.png)
![kiali-graph03](https://github.com/GrassShrimp/kind-istio-kiali/blob/master/kiali-graph03.png)