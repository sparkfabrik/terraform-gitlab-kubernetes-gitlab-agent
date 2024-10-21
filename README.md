# Terraform Gitlab Kubernetes Agent

This module creates all the necessary resources to deploy a Gitlab Agent on a Kubernetes cluster.

It uses the Gitlab provider to register the agent on the Gitlab server. The generated registration token is use to create an Helm release of the Gitlab Agent in the cluster.

If required (`gitlab_agent_grant_access_to_entire_root_namespace` configured to `true`), it also creates the necessary configuration files in the given Gitlab project, granting access to all the projects in the root namespace and subgroups.

**ATTENTION**: you have to manually create the project that will host the Gitlab Agent configuration in Gitlab before running this module.

From version 0.7.0 if you set `gitlab_project_name` the module will create gitlab project automatically. This new behavior requires the provider to have the proper permissions to create the project in the namespace.

## RBAC configuration for the Gitlab Agent service account

This module uses the default configuration of the Gitlab Agent Helm chart. The default configuration grants to the Gitlab Agent service account the `cluster-admin` ClusterRole. If you want to change this configuration, you can use the `helm_additional_values` variable to pass additional values to the Helm chart.

## How to configure the Gitlab provider

This module requires a Gitlab provider to be configured in your Terraform project. The following snippet shows how to configure the provider:

```hcl
provider "gitlab" {
  base_url = "https://gitlab.com/api/v4/"
  token    = var.gitlab_token
}
```

**ATTENTION:** as described in the [Gitlab provider documentation](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs), the `CI_JOB_TOKEN` could cause issues when used as `token` for the Gitlab provider. For this module in particular, the `gitlab_cluster_agent` and `gitlab_cluster_agent_token` resources require authorization to access to the `/users` Gitlab API endpoint, which is not granted by the `CI_JOB_TOKEN`. You have to use a Gitlab personal access token with the `api` scope to authenticate the provider.

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_gitlab"></a> [gitlab](#provider\_gitlab) | >= 15.7 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.23 |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_gitlab"></a> [gitlab](#requirement\_gitlab) | >= 15.7 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.23 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agent_kas_address"></a> [agent\_kas\_address](#input\_agent\_kas\_address) | The address of the Gitlab Kubernetes Agent Server (KAS). | `string` | `"kas.gitlab.com"` | no |
| <a name="input_agent_replicas"></a> [agent\_replicas](#input\_agent\_replicas) | The number of replicas of the Gitlab Agent. | `number` | `1` | no |
| <a name="input_create_default_pod_anti_affinity"></a> [create\_default\_pod\_anti\_affinity](#input\_create\_default\_pod\_anti\_affinity) | Create default podAntiAffinity rules for the Gitlab Agent pods. | `bool` | `true` | no |
| <a name="input_create_namespace"></a> [create\_namespace](#input\_create\_namespace) | Create namespace for the helm release. If false, the namespace must be created before using this module. | `bool` | `true` | no |
| <a name="input_gitlab_agent_append_to_config_file"></a> [gitlab\_agent\_append\_to\_config\_file](#input\_gitlab\_agent\_append\_to\_config\_file) | Append the Gitlab Agent configuration to the configuration file created for the entire root namespace. This variable is only used when `gitlab_agent_grant_access_to_entire_root_namespace` is true. | `string` | `""` | no |
| <a name="input_gitlab_agent_branch_name"></a> [gitlab\_agent\_branch\_name](#input\_gitlab\_agent\_branch\_name) | The branch name where the Gitlab Agent configuration will be stored. | `string` | `"main"` | no |
| <a name="input_gitlab_agent_commmit_message"></a> [gitlab\_agent\_commmit\_message](#input\_gitlab\_agent\_commmit\_message) | The commit message to use when committing the Gitlab Agent configuration file. You can use the placeholder `{{gitlab_agent_name}}` to reference the Gitlab Agent name. | `string` | `"[CI] Add agent config file for {{gitlab_agent_name}}"` | no |
| <a name="input_gitlab_agent_create_variables_in_root_namespace"></a> [gitlab\_agent\_create\_variables\_in\_root\_namespace](#input\_gitlab\_agent\_create\_variables\_in\_root\_namespace) | Create two Gitlab CI/CD variables in the root namespace useful to configure the Kubernetes context and use the Gitlab Agent. These variables are created in the root namespace of the project defined in `gitlab_project_path_with_namespace`, which is the project that hosts the Gitlab Agent configuration. | `bool` | `true` | no |
| <a name="input_gitlab_agent_custom_config_file_content"></a> [gitlab\_agent\_custom\_config\_file\_content](#input\_gitlab\_agent\_custom\_config\_file\_content) | The content of the Gitlab Agent configuration file. If not provided and `gitlab_agent_grant_access_to_entire_root_namespace` is true, the default configuration file will be used and the root namespace will be granted access to the Gitlab Agent. If you set this variable, it takes precedence over `gitlab_agent_grant_access_to_entire_root_namespace`. | `string` | `""` | no |
| <a name="input_gitlab_agent_grant_access_to_entire_root_namespace"></a> [gitlab\_agent\_grant\_access\_to\_entire\_root\_namespace](#input\_gitlab\_agent\_grant\_access\_to\_entire\_root\_namespace) | Grant access to the entire root namespace. If false, you can provide a custom configuration file content using the variable `gitlab_agent_custom_config_file_content`. Otherwise, you will have to manually manage the access to the Gitlab Agent committing the proper configuration to the Gitlab project. | `bool` | `true` | no |
| <a name="input_gitlab_agent_grant_user_access_to_root_namespace"></a> [gitlab\_agent\_grant\_user\_access\_to\_root\_namespace](#input\_gitlab\_agent\_grant\_user\_access\_to\_root\_namespace) | Grant `user_access` to the root namespace. | `bool` | `false` | no |
| <a name="input_gitlab_agent_name"></a> [gitlab\_agent\_name](#input\_gitlab\_agent\_name) | The name of the Gitlab Agent. | `string` | n/a | yes |
| <a name="input_gitlab_agent_token_description"></a> [gitlab\_agent\_token\_description](#input\_gitlab\_agent\_token\_description) | The description of the Gitlab Agent token. You can use the placeholder `{{gitlab_agent_name}}` to reference the Gitlab Agent name. | `string` | `"Token for the Gitlab Agent {{gitlab_agent_name}}."` | no |
| <a name="input_gitlab_agent_token_name"></a> [gitlab\_agent\_token\_name](#input\_gitlab\_agent\_token\_name) | The name of the Gitlab Agent token.  You can use the placeholder `{{gitlab_agent_name}}` to reference the Gitlab Agent name. | `string` | `"{{gitlab_agent_name}}-token"` | no |
| <a name="input_gitlab_agent_variable_name_agent_id"></a> [gitlab\_agent\_variable\_name\_agent\_id](#input\_gitlab\_agent\_variable\_name\_agent\_id) | The name of the Gitlab CI/CD variable that stores the Gitlab Agent ID. | `string` | `"GITLAB_AGENT_ID"` | no |
| <a name="input_gitlab_agent_variable_name_agent_project"></a> [gitlab\_agent\_variable\_name\_agent\_project](#input\_gitlab\_agent\_variable\_name\_agent\_project) | The name of the Gitlab CI/CD variable that stores the Gitlab Agent project path. | `string` | `"GITLAB_AGENT_PROJECT"` | no |
| <a name="input_gitlab_project_path_with_namespace"></a> [gitlab\_project\_path\_with\_namespace](#input\_gitlab\_project\_path\_with\_namespace) | The path with namespace of the Gitlab project that hosts the Gitlab Agent configuration. The project must be created in Gitlab before running this module. The configured Gitlab provider must have write access to the project. | `string` | n/a | yes |
| <a name="input_helm_additional_values"></a> [helm\_additional\_values](#input\_helm\_additional\_values) | Additional values to be passed to the Helm chart. | `list(string)` | `[]` | no |
| <a name="input_helm_chart_version"></a> [helm\_chart\_version](#input\_helm\_chart\_version) | The version of the gitlab-agent Helm chart. You can see the available versions at https://gitlab.com/gitlab-org/charts/gitlab-agent/-/tags, or using the command `helm search repo gitlab/gitlab-agent -l` after adding the Gitlab Helm repository. | `string` | `"2.5.0"` | no |
| <a name="input_helm_release_name"></a> [helm\_release\_name](#input\_helm\_release\_name) | The name of the Helm release. | `string` | `"gitlab-agent"` | no |
| <a name="input_k8s_additional_labels"></a> [k8s\_additional\_labels](#input\_k8s\_additional\_labels) | Additional labels to apply to the kubernetes resources. | `map(string)` | `{}` | no |
| <a name="input_k8s_default_labels"></a> [k8s\_default\_labels](#input\_k8s\_default\_labels) | Labels to apply to the kubernetes resources. These are opinionated labels, you can add more labels using the variable `additional_k8s_labels`. If you want to remove a label, you can override it with an empty map(string). | `map(string)` | <pre>{<br>  "managed-by": "terraform",<br>  "scope": "gitlab-agent"<br>}</pre> | no |
| <a name="input_k8s_gitlab_agent_token_secret_name"></a> [k8s\_gitlab\_agent\_token\_secret\_name](#input\_k8s\_gitlab\_agent\_token\_secret\_name) | The name of the Kubernetes secret that will store the Gitlab Agent token. You can use the placeholder `{{gitlab_agent_name}}` to reference the Gitlab Agent name. | `string` | `"{{gitlab_agent_name}}-token"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | The namespace in which the Gitlab Agent resources will be created. | `string` | `"gitlab-agent"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_gitlab_agent_kubernetes_context_variables"></a> [gitlab\_agent\_kubernetes\_context\_variables](#output\_gitlab\_agent\_kubernetes\_context\_variables) | The Gitlab Agent information to be used to configure the Kubernetes context. |
| <a name="output_gitlab_agent_token"></a> [gitlab\_agent\_token](#output\_gitlab\_agent\_token) | The token of the Gitlab Agent. |
| <a name="output_gitlab_agents_project_id"></a> [gitlab\_agents\_project\_id](#output\_gitlab\_agents\_project\_id) | The ID of the Gitlab project where the Gitlab Agents are installed. |
| <a name="output_gitlab_root_namespace_id"></a> [gitlab\_root\_namespace\_id](#output\_gitlab\_root\_namespace\_id) | The ID of the root namespace of the Gitlab Agents project. |
| <a name="output_k8s_common_labels"></a> [k8s\_common\_labels](#output\_k8s\_common\_labels) | Common labels to apply to the kubernetes resources. |
| <a name="output_k8s_gitlab_agent_token_secret_name"></a> [k8s\_gitlab\_agent\_token\_secret\_name](#output\_k8s\_gitlab\_agent\_token\_secret\_name) | The name of the Kubernetes secret that will store the Gitlab Agent token. |

## Resources

| Name | Type |
|------|------|
| [gitlab_cluster_agent.this](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/cluster_agent) | resource |
| [gitlab_cluster_agent_token.this](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/cluster_agent_token) | resource |
| [gitlab_group_variable.this](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/group_variable) | resource |
| [gitlab_repository_file.this](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/resources/repository_file) | resource |
| [helm_release.this](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_secret_v1.gitlab_agent_token_secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [gitlab_group.root_namespace](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/data-sources/group) | data source |
| [gitlab_project.this](https://registry.terraform.io/providers/gitlabhq/gitlab/latest/docs/data-sources/project) | data source |
| [kubernetes_namespace_v1.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/data-sources/namespace_v1) | data source |

## Modules

No modules.

<!-- END_TF_DOCS -->
