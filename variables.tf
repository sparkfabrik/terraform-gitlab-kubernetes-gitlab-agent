variable "gitlab_project_details" {
  description = "Details of the Gitlab project including name, group, and description"
  type = object({
    name        = string
    group       = string
    description = string
  })
  default = {
    name        = ""
    group       = ""
    description = ""
  }
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

variable "gitlab_agent_grant_access_to_entire_root_namespace" {
  description = "Grant access to the entire root namespace. If false, you can provide a custom configuration file content using the variable `gitlab_agent_custom_config_file_content`. Otherwise, you will have to manually manage the access to the Gitlab Agent committing the proper configuration to the Gitlab project."
  type        = bool
  default     = true
}

variable "gitlab_agent_grant_user_access_to_root_namespace" {
  description = "Grant `user_access` to the root namespace."
  type        = bool
  default     = false
}

variable "gitlab_agent_append_to_config_file" {
  description = "Append the Gitlab Agent configuration to the configuration file created for the entire root namespace. This variable is only used when `gitlab_agent_grant_access_to_entire_root_namespace` is true."
  type        = string
  default     = ""

}

variable "gitlab_agent_custom_config_file_content" {
  description = "The content of the Gitlab Agent configuration file. If not provided and `gitlab_agent_grant_access_to_entire_root_namespace` is true, the default configuration file will be used and the root namespace will be granted access to the Gitlab Agent. If you set this variable, it takes precedence over `gitlab_agent_grant_access_to_entire_root_namespace`."
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

variable "gitlab_agent_create_variables_in_root_namespace" {
  description = "Create two Gitlab CI/CD variables in the root namespace useful to configure the Kubernetes context and use the Gitlab Agent. These variables are created in the root namespace of the project defined in `gitlab_project_path_with_namespace`, which is the project that hosts the Gitlab Agent configuration."
  type        = bool
  default     = true
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
  default     = "2.6.2"
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

variable "agent_kas_address" {
  description = "The address of the Gitlab Kubernetes Agent Server (KAS)."
  type        = string
  default     = "kas.gitlab.com"
}

variable "create_default_pod_anti_affinity" {
  description = "Create default podAntiAffinity rules for the Gitlab Agent pods."
  type        = bool
  default     = true
}
