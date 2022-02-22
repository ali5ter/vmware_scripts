terraform {
  required_providers {
    tanzu-mission-control = {
      source  = "vmware/tanzu-mission-control"
      version = "1.0.1"
    }
  }
}

provider "tanzu-mission-control" {
  endpoint = var.TMC_API_ENDPOINT_HOSTNAME
  vmw_cloud_api_token = var.CSP_API_TOKEN
  vmw_cloud_endpoint = var.CSP_ENDPOINT_HOSTNAME
}