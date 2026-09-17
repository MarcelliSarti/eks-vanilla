terraform {
  required_providers {
    helm = {
      source                = "hashicorp/helm"
      configuration_aliases = [helm]
    }
  }
}
