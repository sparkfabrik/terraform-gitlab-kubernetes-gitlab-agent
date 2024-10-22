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
  description = "The ID of the root namespace of the Gitlab Agents project."
  value       = data.gitlab_group.root_namespace.group_id
}
