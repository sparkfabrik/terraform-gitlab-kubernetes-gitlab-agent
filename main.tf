locals {
  helm_chart_url  = "https://charts.gitlab.io"
  helm_chart_name = "gitlab-agent"

  k8s_common_labels = merge(
    var.k8s_default_labels,
    var.k8s_additional_labels,
  )

  final_namespace = var.create_namespace ? resource.kubernetes_namespace_v1.this[0].metadata[0].name : data.kubernetes_namespace_v1.this[0].metadata[0].name

  gitlab_agent_token_name_computed            = replace(var.gitlab_agent_token_name, "{{gitlab_agent_name}}", var.gitlab_agent_name)
  gitlab_agent_token_description_computed     = replace(var.gitlab_agent_token_description, "{{gitlab_agent_name}}", var.gitlab_agent_name)
  gitlab_agent_commmit_message_computed       = replace(var.gitlab_agent_commmit_message, "{{gitlab_agent_name}}", var.gitlab_agent_name)
  k8s_gitlab_agent_token_secret_name_computed = replace(var.k8s_gitlab_agent_token_secret_name, "{{gitlab_agent_name}}", var.gitlab_agent_name)

  # Gitlab Agent configuration file
  final_configuration_file_content = var.gitlab_agent_custom_config_file_content != "" ? var.gitlab_agent_custom_config_file_content : (var.gitlab_agent_grant_access_to_entire_root_namespace ? templatefile("${path.module}/files/config.yaml.tftpl", { root_namespace = data.gitlab_group.root_namespace.path, gitlab_agent_append_to_config_file = var.gitlab_agent_append_to_config_file, gitlab_agent_grant_user_access_to_root_namespace = var.gitlab_agent_grant_user_access_to_root_namespace }) : "")

  # Gitlab Agent CI/CD variables
  gitlab_agent_kubernetes_context_variables = {
    (var.gitlab_agent_variable_name_agent_id) : gitlab_cluster_agent.this.name,
    (var.gitlab_agent_variable_name_agent_project) : data.gitlab_project.this.path_with_namespace,
  }
}

# Gitlab resources

resource "gitlab_project" "project" {
  count        = var.gitlab_project_details.name ? 0 : 1
  name         = var.gitlab_project_details.name
  namespace_id = var.gitlab_project_details.group
  description  = var.gitlab_project_details.description
}

data "gitlab_project" "this" {
  path_with_namespace = var.gitlab_project_path_with_namespace
}

data "gitlab_group" "root_namespace" {
  group_id = data.gitlab_project.this.namespace_id
}

resource "gitlab_cluster_agent" "this" {
  project = data.gitlab_project.this.id
  name    = var.gitlab_agent_name
}

resource "gitlab_cluster_agent_token" "this" {
  project     = data.gitlab_project.this.id
  agent_id    = gitlab_cluster_agent.this.agent_id
  name        = local.gitlab_agent_token_name_computed
  description = local.gitlab_agent_token_description_computed
}

resource "gitlab_repository_file" "this" {
  count = trimspace(local.final_configuration_file_content) != "" ? 1 : 0

  project        = data.gitlab_project.this.id
  branch         = var.gitlab_agent_branch_name
  commit_message = local.gitlab_agent_commmit_message_computed
  file_path      = ".gitlab/agents/${gitlab_cluster_agent.this.name}/config.yaml"
  encoding       = "text"
  content        = local.final_configuration_file_content

  # Force the creation of the file only after the creation of the helm release.
  # This is to avoid the creation of the file before the creation of the agent.
  depends_on = [
    helm_release.this
  ]
}

resource "gitlab_group_variable" "this" {
  for_each = var.gitlab_agent_create_variables_in_root_namespace ? local.gitlab_agent_kubernetes_context_variables : {}

  group     = data.gitlab_group.root_namespace.group_id
  key       = each.key
  value     = each.value
  protected = false
  masked    = false

  # Force the creation of the variables only after the creation of the helm release.
  # This is to avoid the use of the agent before the creation of the agent.
  depends_on = [
    helm_release.this
  ]
}

# Kubernetes resources
resource "kubernetes_namespace_v1" "this" {
  count = var.create_namespace ? 1 : 0

  metadata {
    labels = merge(
      { name = var.namespace },
      local.k8s_common_labels,
    )

    name = var.namespace
  }
}

data "kubernetes_namespace_v1" "this" {
  count = var.create_namespace ? 0 : 1

  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret_v1" "gitlab_agent_token_secret" {
  metadata {
    name      = local.k8s_gitlab_agent_token_secret_name_computed
    namespace = local.final_namespace
  }

  data = {
    token = gitlab_cluster_agent_token.this.token
  }
}

# Helm release
resource "helm_release" "this" {
  name             = var.helm_release_name
  repository       = local.helm_chart_url
  chart            = local.helm_chart_name
  version          = var.helm_chart_version
  namespace        = local.final_namespace
  create_namespace = false

  values = concat(
    [
      templatefile(
        "${path.module}/files/values.yaml.tftpl",
        {
          k8s_common_labels       = local.k8s_common_labels
          agent_replicas          = var.agent_replicas
          agent_kas_address       = var.agent_kas_address
          agent_token_secret_name = kubernetes_secret_v1.gitlab_agent_token_secret.metadata[0].name
          # Variables used to configure the default podAntiAffinity for the Gitlab Agent
          create_default_pod_anti_affinity = var.create_default_pod_anti_affinity
          helm_release_name                = var.helm_release_name
        }
      ),
    ],
    var.helm_additional_values
  )
}
