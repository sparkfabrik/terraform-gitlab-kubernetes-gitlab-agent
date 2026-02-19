variable "gitlab_project_name" {
  description = "The name of the Gitlab project that hosts the Gitlab Agent configuration. If not provided, the module will use the project defined in `gitlab_project_path_with_namespace`."
  type        = string
  default     = ""
}

variable "gitlab_agent_deploy_enabled" {
  description = "Whether to deploy the GitLab Agent components. If false, only creates the GitLab Agent token, Kubernetes namespace and secret without deploying the agent itself."
  type        = bool
  default     = true
}

variable "gitlab_project_path_with_namespace" {
  description = "The path with namespace of the Gitlab project that hosts the Gitlab Agent configuration. The project must be created in Gitlab before running this module. The configured Gitlab provider must have write access to the project."
  type        = string
}

variable "gitlab_agent_name" {
  description = "The name of the Gitlab Agent."
  type        = string
}

variable "gitlab_agent_token_name" {
  description = "The name of the Gitlab Agent token.  You can use the placeholder `{{gitlab_agent_name}}` to reference the Gitlab Agent name."
  type        = string
  default     = "{{gitlab_agent_name}}-token"
}

variable "gitlab_agent_token_description" {
  description = "The description of the Gitlab Agent token. You can use the placeholder `{{gitlab_agent_name}}` to reference the Gitlab Agent name."
  type        = string
  default     = "Token for the Gitlab Agent {{gitlab_agent_name}}."
}

variable "operate_at_root_group_level" {
  description = "Operate at root group level. If true, grants access to entire root namespace and creates variables in root group. If false, behavior depends on groups_enabled and projects_enabled. This replaces gitlab_agent_grant_access_to_entire_root_namespace and gitlab_agent_create_variables_in_root_namespace."
  type        = bool
  default     = true
}

variable "gitlab_agent_grant_user_access_to_root_namespace" {
  description = "Grant `user_access` to the root namespace."
  type        = bool
  default     = false
}

variable "groups_enabled" {
  description = "List of group paths where the GitLab Agent should be enabled. Only used when operate_at_root_group_level is false. If empty and projects_enabled is also empty, the parent group of the agent project will be used automatically."
  type        = list(string)
  default     = []
}

variable "projects_enabled" {
  description = "List of project paths (with namespace) where the GitLab Agent should be enabled. Only used when operate_at_root_group_level is false. If empty and groups_enabled is also empty, the parent group of the agent project will be used automatically."
  type        = list(string)
  default     = []
}

variable "gitlab_agent_append_to_config_file" {
  description = "Append custom configuration to the Gitlab Agent configuration file. This content will be added at the end of the generated configuration."
  type        = string
  default     = ""

}

variable "gitlab_agent_custom_config_file_content" {
  description = "The content of the Gitlab Agent configuration file. If not provided, the default configuration file will be generated based on `operate_at_root_group_level`, `groups_enabled`, and `projects_enabled`. If you set this variable, it takes precedence over the automatic configuration generation."
  type        = string
  default     = ""
}

variable "gitlab_agent_commmit_message" {
  description = "The commit message to use when committing the Gitlab Agent configuration file. You can use the placeholder `{{gitlab_agent_name}}` to reference the Gitlab Agent name."
  type        = string
  default     = "[CI] Add agent config file for {{gitlab_agent_name}}"
}

variable "gitlab_agent_branch_name" {
  description = "The branch name where the Gitlab Agent configuration will be stored."
  type        = string
  default     = "main"
}

variable "gitlab_agent_variable_name_agent_id" {
  description = "The name of the Gitlab CI/CD variable that stores the Gitlab Agent ID."
  type        = string
  default     = "GITLAB_AGENT_ID"
}

variable "gitlab_agent_variable_name_agent_project" {
  description = "The name of the Gitlab CI/CD variable that stores the Gitlab Agent project path."
  type        = string
  default     = "GITLAB_AGENT_PROJECT"
}

variable "create_namespace" {
  description = "Create namespace for the helm release. If false, the namespace must be created before using this module."
  type        = bool
  default     = true
}

variable "namespace" {
  description = "The namespace in which the Gitlab Agent resources will be created."
  type        = string
  default     = "gitlab-agent"
}

variable "helm_release_name" {
  description = "The name of the Helm release."
  type        = string
  default     = "gitlab-agent"
}

variable "helm_chart_version" {
  description = "The version of the gitlab-agent Helm chart. You can see the available versions at https://gitlab.com/gitlab-org/charts/gitlab-agent/-/tags, or using the command `helm search repo gitlab/gitlab-agent -l` after adding the Gitlab Helm repository."
  type        = string
  default     = "2.23.0"
}

variable "helm_additional_values" {
  description = "Additional values to be passed to the Helm chart."
  type        = list(string)
  default     = []
}

variable "k8s_default_labels" {
  description = "Labels to apply to the kubernetes resources. These are opinionated labels, you can add more labels using the variable `additional_k8s_labels`. If you want to remove a label, you can override it with an empty map(string)."
  type        = map(string)
  default = {
    managed-by = "terraform"
    scope      = "gitlab-agent"
  }
}

variable "k8s_additional_labels" {
  description = "Additional labels to apply to the kubernetes resources."
  type        = map(string)
  default     = {}
}

variable "k8s_gitlab_agent_token_secret_name" {
  type        = string
  description = "The name of the Kubernetes secret that will store the Gitlab Agent token. You can use the placeholder `{{gitlab_agent_name}}` to reference the Gitlab Agent name."
  default     = "{{gitlab_agent_name}}-token"
}

variable "agent_replicas" {
  description = "The number of replicas of the Gitlab Agent."
  type        = number
  default     = 1
}

variable "create_default_pod_anti_affinity" {
  description = "Create default podAntiAffinity rules for the Gitlab Agent pods."
  type        = bool
  default     = true
}

variable "assign_current_user_as_maintainer" {
  description = "Assign the current GitLab user (from the GitLab provider) as a maintainer of the created project. This is useful to ensure that the user has rights to commit and push the GitLab Agent configuration file."
  type        = bool
  default     = false
}
