terraform {
  required_providers {
    kind = {
      source  = "justenwalker/kind"
      version = "0.11.0-rc.1"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.6.1"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.3.0"
    }
    external = {
      source = "hashicorp/external"
      version = "2.1.0"
    }
    null = {
      source = "hashicorp/null"
      version = "3.1.0"
    }
  }
}
provider "kubernetes" {
  config_context = kind_cluster.k8s-cluster.context
  config_path    = "~/.kube/config"
}
provider "helm" {
  kubernetes {
    config_context = kind_cluster.k8s-cluster.context
    config_path    = "~/.kube/config"
  }
}
provider "external" {}
provider "null" {}