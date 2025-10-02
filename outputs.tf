output "k8s_common_labels" {
  value       = local.k8s_common_labels
  description = "Common labels to apply to the kubernetes resources."
}

output "k8s_gitlab_agent_token_secret_name" {
  value       = local.k8s_gitlab_agent_token_secret_name_computed
  description = "The name of the Kubernetes secret that will store the Gitlab Agent token."
}

output "gitlab_agent_token" {
  value       = gitlab_cluster_agent_token.this.token
  sensitive   = true
  description = "The token of the Gitlab Agent."
}

output "gitlab_agent_kubernetes_context_variables" {
  value       = local.gitlab_agent_kubernetes_context_variables
  description = "The Gitlab Agent information to be used to configure the Kubernetes context."
}

output "gitlab_agents_project_id" {
  description = "The ID of the Gitlab project where the Gitlab Agents are installed."
  value       = local.project_id
}

output "gitlab_root_namespace_id" {
  description = "The ID of the root namespace of the Gitlab Agents project. Only available when operate_at_root_group_level is true."
  value       = local.operate_at_root_group_level_computed ? data.gitlab_group.root_namespace.group_id : null
}

output "gitlab_enabled_groups" {
  description = "List of groups where the GitLab Agent has been enabled with variables."
  value       = local.groups_to_enable
}

output "gitlab_enabled_projects" {
  description = "List of projects where the GitLab Agent has been enabled with variables."
  value       = local.projects_to_enable
}

output "gitlab_parent_group_auto_detected" {
  description = "Whether the parent group was automatically detected."
  value       = local.auto_detect_parent
}

output "operate_at_root_group_level" {
  description = "The computed value of operate_at_root_group_level (includes backward compatibility)."
  value       = local.operate_at_root_group_level_computed
}
