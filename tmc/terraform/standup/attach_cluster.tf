resource "tmc_cluster" "attach_cluster_without_apply" {
  management_cluster_name = var.TMC_MNGMT_CLUSTER
  provisioner_name        = var.TMC_PROVISIONER
  name                    = var.TMC_CLUSTER_NAME

  meta {
    description = var.TMC_DESCRIPTION
    labels      = { 
        "env" : "test", 
        "generatedFrom" : "vmware_scripts", 
        "using" : "terraform" 
    }
  }

  spec {
    # Dependency on the clsuter group wwe want stood up
    cluster_group = tmc_cluster_group.create_cluster_group.name
  }

  wait_until_ready = true
}