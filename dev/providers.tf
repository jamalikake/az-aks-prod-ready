terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      # AKS creates a ContainerInsights solution that Terraform doesn't manage;
      # skip the orphan-resource check so terraform destroy can delete the RG.
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_client_config" "current" {}

# Used by the helm provider to locate the cluster endpoint and CA.
# Requires the cluster to exist before Terraform plans any helm_release resources.
data "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${var.project}-${var.environment}"
  resource_group_name = "rg-${var.project}-${var.environment}"
}

# kubelogin --login azurecli uses the active Azure CLI session (OIDC in CI,
# az login in local dev). Server ID 6dae42f8-... is the well-known AKS AAD
# app ID for Azure public cloud.
provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.this.kube_config[0].host
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args        = ["get-token", "--login", "azurecli", "--server-id", "6dae42f8-4368-4678-94ff-3960e28e3630"]
    }
  }
}
