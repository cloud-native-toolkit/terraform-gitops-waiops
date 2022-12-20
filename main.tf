locals {
  name          = "terraform-gitops-waiops"
  yaml_dir      = "${path.cwd}/.tmp/${local.name}/chart/${local.name}"
  layer = "services"
  type  = "operators"
  application_branch = "main"
  layer_config = var.gitops_config[local.layer]
    values_content = {
      "ibm-cp4waiops-operator" = {
        namespace = var.namespace
        subscriptions = {
          ibmwaiops = {
            name = "ibm-aiops-orchestrator"
            subscription = {
              channel = var.channel
              installPlanApproval = "Automatic"
              name = "ibm-aiops-orchestrator"
              source = var.catalog
              sourceNamespace = var.catalog_namespace
            }
          }
        }
        infra = {
          ibmwaiops = {
            namespace = var.namespace
            name = "ibm-infrastructure-automation-operator"
            subscription = {
              channel = var.channel
              installPlanApproval = "Automatic"
              name = "ibm-infrastructure-automation-operator"
              source = var.catalog
              sourceNamespace = var.catalog_namespace
            }
          }
        }
        event = {
          namespace = var.namespace
          ibmwaiops = {
            name = "noi"
            subscription = {
              channel = var.channel_event_manager
              installPlanApproval = "Automatic"
              name = "noi"
              source = var.catalog
              sourceNamespace = var.catalog_namespace
            }
          }
        }
      }
  }
  values_file = "values.yaml"
}

resource null_resource create_yaml {
  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${local.name}' '${local.yaml_dir}'"

    environment = {
      VALUES_CONTENT = yamlencode(local.values_content)
    }
  }
}

resource gitops_module module {
  depends_on = [null_resource.create_yaml]

  name = local.name
  namespace = var.namespace
  content_dir = local.yaml_dir
  server_name = var.server_name
  layer = local.layer
  type = local.type
  branch = local.application_branch
  config = yamlencode(var.gitops_config)
  credentials = yamlencode(var.git_credentials)
}
