resource "tmc_cluster_group" "create_cluster_group" {
  name = var.TMC_CLUSTER_GROUP
  meta {
    description = var.TMC_DESCRIPTION
    labels      = { 
        "env" : "test", 
        "generatedFrom" : "vmware_scripts", 
        "using" : "terraform" 
    }
  }
}