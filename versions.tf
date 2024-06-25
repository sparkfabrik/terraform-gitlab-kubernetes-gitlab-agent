terraform {
  required_version = ">= 1.5"

  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = ">= 15.7"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0"
    }
  }
}
