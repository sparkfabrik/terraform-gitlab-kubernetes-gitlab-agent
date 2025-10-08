locals {
  helm_chart_url  = "https://charts.gitlab.io"
  helm_chart_name = "gitlab-agent"

  k8s_common_labels = merge(
    var.k8s_default_labels,
    var.k8s_additional_labels,
  )

  final_namespace = var.create_namespace ? resource.kubernetes_namespace_v1.this[0].metadata[0].name : data.kubernetes_namespace_v1.this[0].metadata[0].name

  use_existing_project        = var.gitlab_project_name == "" ? 1 : 0
  project_id                  = local.use_existing_project == 1 ? data.gitlab_project.this[0].id : gitlab_project.project[0].id
  project_path_with_namespace = local.use_existing_project == 1 ? data.gitlab_project.this[0].path_with_namespace : gitlab_project.project[0].path_with_namespace
  project_root_namespace      = split("/", var.gitlab_project_path_with_namespace)[0]

  gitlab_agent_token_name_computed            = replace(var.gitlab_agent_token_name, "{{gitlab_agent_name}}", var.gitlab_agent_name)
  gitlab_agent_token_description_computed     = replace(var.gitlab_agent_token_description, "{{gitlab_agent_name}}", var.gitlab_agent_name)
  gitlab_agent_commmit_message_computed       = replace(var.gitlab_agent_commmit_message, "{{gitlab_agent_name}}", var.gitlab_agent_name)
  k8s_gitlab_agent_token_secret_name_computed = replace(var.k8s_gitlab_agent_token_secret_name, "{{gitlab_agent_name}}", var.gitlab_agent_name)

  # Determine the parent group of the project
  project_path_parts = split("/", var.gitlab_project_path_with_namespace)
  parent_group_path  = length(local.project_path_parts) > 1 ? join("/", slice(local.project_path_parts, 0, length(local.project_path_parts) - 1)) : ""

  # Determine if we are in auto-parent mode
  auto_detect_parent = !var.operate_at_root_group_level && length(concat(var.groups_enabled, var.projects_enabled)) == 0

  # Final list of groups to enable
  groups_to_enable = var.operate_at_root_group_level ? [] : (
    local.auto_detect_parent ? [local.parent_group_path] : var.groups_enabled
  )

  # Final list of projects to enable
  projects_to_enable = var.operate_at_root_group_level ? [] : (
    local.auto_detect_parent ? [] : var.projects_enabled
  )

  # Gitlab Agent configuration file
  final_configuration_file_content = var.gitlab_agent_custom_config_file_content != "" ? var.gitlab_agent_custom_config_file_content : templatefile("${path.module}/files/config.yaml.tftpl", {
    operate_at_root_group_level                      = var.operate_at_root_group_level
    gitlab_agent_grant_user_access_to_root_namespace = var.gitlab_agent_grant_user_access_to_root_namespace
    root_namespace                                   = data.gitlab_group.root_namespace.path
    groups_to_enable                                 = local.groups_to_enable
    projects_to_enable                               = local.projects_to_enable
    gitlab_agent_append_to_config_file               = var.gitlab_agent_append_to_config_file
  })

  # Gitlab Agent CI/CD variables
  gitlab_agent_kubernetes_context_variables = {
    (var.gitlab_agent_variable_name_agent_id) : gitlab_cluster_agent.this.name,
    (var.gitlab_agent_variable_name_agent_project) : local.project_path_with_namespace,
  }
}

# Gitlab resources
data "gitlab_current_user" "this" {}

data "gitlab_metadata" "this" {}

data "gitlab_project" "this" {
  count               = local.use_existing_project
  path_with_namespace = var.gitlab_project_path_with_namespace
}

data "gitlab_group" "root_namespace" {
  full_path = local.project_root_namespace
}

# Data source for parent group (used for project creation when not at root level, and for auto-detect mode)
data "gitlab_group" "parent_group" {
  count     = !var.operate_at_root_group_level && local.parent_group_path != "" ? 1 : 0
  full_path = local.parent_group_path
}

# Data source for the specified groups
data "gitlab_group" "enabled_groups" {
  for_each  = !var.operate_at_root_group_level && !local.auto_detect_parent ? toset(var.groups_enabled) : toset([])
  full_path = each.value
}

# Data source for the specified projects
data "gitlab_project" "enabled_projects" {
  for_each            = !var.operate_at_root_group_level && !local.auto_detect_parent ? toset(var.projects_enabled) : toset([])
  path_with_namespace = each.value
}

resource "gitlab_project" "project" {
  count        = local.use_existing_project == 0 ? 1 : 0
  name         = var.gitlab_project_name
  namespace_id = var.operate_at_root_group_level ? data.gitlab_group.root_namespace.group_id : data.gitlab_group.parent_group[0].group_id
}

resource "gitlab_project_membership" "project" {
  count        = var.autoassign_current_user_as_maintainer ? 1 : 0
  project      = local.project_id
  user_id      = data.gitlab_current_user.this.id
  access_level = "maintainer"
}

resource "gitlab_cluster_agent" "this" {
  project = local.project_id
  name    = var.gitlab_agent_name
}

resource "gitlab_cluster_agent_token" "this" {
  project = local.project_id

  agent_id    = gitlab_cluster_agent.this.agent_id
  name        = local.gitlab_agent_token_name_computed
  description = local.gitlab_agent_token_description_computed
}

resource "gitlab_repository_file" "this" {
  count = trimspace(local.final_configuration_file_content) != "" ? 1 : 0

  project = local.project_id

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

# Variables for root group (when operate_at_root_group_level is true)
resource "gitlab_group_variable" "root_namespace" {
  for_each = var.operate_at_root_group_level ? local.gitlab_agent_kubernetes_context_variables : {}

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

# Variables for specific groups (when operate_at_root_group_level is false)
resource "gitlab_group_variable" "enabled_groups" {
  for_each = !var.operate_at_root_group_level && length(local.groups_to_enable) > 0 ? {
    for pair in setproduct(keys(local.gitlab_agent_kubernetes_context_variables), local.groups_to_enable) :
    "${pair[1]}__${pair[0]}" => {
      group_path = pair[1]
      key        = pair[0]
      value      = local.gitlab_agent_kubernetes_context_variables[pair[0]]
    }
  } : {}

  group     = local.auto_detect_parent && each.value.group_path == local.parent_group_path ? data.gitlab_group.parent_group[0].group_id : data.gitlab_group.enabled_groups[each.value.group_path].group_id
  key       = each.value.key
  value     = each.value.value
  protected = false
  masked    = false
}

# Variables for specific projects (when operate_at_root_group_level is false)
resource "gitlab_project_variable" "enabled_projects" {
  for_each = !var.operate_at_root_group_level && length(local.projects_to_enable) > 0 ? {
    for pair in setproduct(keys(local.gitlab_agent_kubernetes_context_variables), local.projects_to_enable) :
    "${pair[1]}__${pair[0]}" => {
      project_path = pair[1]
      key          = pair[0]
      value        = local.gitlab_agent_kubernetes_context_variables[pair[0]]
    }
  } : {}

  project   = data.gitlab_project.enabled_projects[each.value.project_path].id
  key       = each.value.key
  value     = each.value.value
  protected = false
  masked    = false
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
  count            = var.gitlab_agent_deploy_enabled ? 1 : 0
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
          agent_kas_address       = data.gitlab_metadata.this.kas.external_url
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
