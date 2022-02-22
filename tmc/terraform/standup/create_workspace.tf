resource "tanzu-mission-control_workspace" "create_workspace" {
  name     = var.TMC_WORKSPACE
  meta {
    description = var.TMC_DESCRIPTION
    labels = {
      "env" : "test",
      "generatedFrom" : "vmware_scripts",
      "using" : "terraform"
    }
  }
}