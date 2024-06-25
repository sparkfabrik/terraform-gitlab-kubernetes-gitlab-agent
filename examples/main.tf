module "gitlab_agents" {
  source = "github.com/sparkfabrik/terraform-gitlab-kubernetes-gitlab-agent?ref=main"

  create_namespace = false
  namespace        = var.namespace

  agent_kas_address                  = var.agent_kas_address
  gitlab_agent_name                  = var.gitlab_agent_name
  gitlab_project_path_with_namespace = var.gitlab_project_path_with_namespace
  helm_release_name                  = var.helm_release_name
}
