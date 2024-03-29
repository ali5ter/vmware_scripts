resource "tanzu-mission-control_cluster" "attach_cluster_without_apply" {
  management_cluster_name = var.TMC_MNGMT_CLUSTER
  provisioner_name        = var.TMC_PROVISIONER
  name                    = var.TMC_CLUSTER_NAME
  attach_k8s_cluster {
    kubeconfig_file = var.KUBECONFIG_FILE
  }
  meta {
    description = var.TMC_DESCRIPTION
    labels = {
      "env" : "test",
      "generatedFrom" : "vmware_scripts",
      "using" : "terraform"
    }
  }
  spec {
    # Dependency on the clsuter group wwe want stood up
    cluster_group = tanzu-mission-control_cluster_group.create_cluster_group.name
  }
}