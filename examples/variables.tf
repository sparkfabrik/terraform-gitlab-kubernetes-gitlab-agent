variable "namespace" {
  description = "The namespace in which the Gitlab Agent resources will be created."
  type        = string
}

variable "agent_kas_address" {
  description = "The address of the Gitlab Kubernetes Agent Server (KAS)."
  type        = string
}

variable "gitlab_agent_name" {
  description = "The name of the Gitlab Agent."
  type        = string
}

variable "gitlab_project_path_with_namespace" {
  description = "The path with namespace of the Gitlab project that hosts the Gitlab Agent configuration. The project must be created in Gitlab before running this module. The configured Gitlab provider must have write access to the project."
  type        = string
}

variable "helm_release_name" {
  description = "The name of the Helm release."
  type        = string
}
