# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2025-10-13

[Compare with previous version](https://github.com/sparkfabrik/terraform-gitlab-kubernetes-gitlab-agent/compare/1.1.0...1.2.0)

### Added
 
- feat: disable autoassign current user by default

## [1.1.0] - 2025-10-08

[Compare with previous version](https://github.com/sparkfabrik/terraform-gitlab-kubernetes-gitlab-agent/compare/1.0.0...1.1.0)

### Added

- refs platform/board#3920: add GitLab provider user as Maintainers of `local.project_id` project.

## [1.0.0] - 2025-10-02

[Compare with previous version](https://github.com/sparkfabrik/terraform-gitlab-kubernetes-gitlab-agent/compare/0.13.0...1.0.0)

### Added

- New variable `operate_at_root_group_level` to simplify configuration and replace the combination of `gitlab_agent_grant_access_to_entire_root_namespace` and `gitlab_agent_create_variables_in_root_namespace`.
- New variable `groups_enabled` to specify groups where the GitLab Agent should be enabled (when not operating at root group level).
- New variable `projects_enabled` to specify projects where the GitLab Agent should be enabled (when not operating at root group level).
- Auto-detection of parent group when `operate_at_root_group_level = false` and no groups/projects are specified.
- Support for creating CI/CD variables in multiple groups and projects simultaneously.
- Dynamic generation of agent configuration file based on enabled groups/projects using `yamlencode()`.
- New outputs: `gitlab_enabled_groups`, `gitlab_enabled_projects`, `gitlab_parent_group_auto_detected`.

### Changed

- Agent configuration file is now dynamically generated based on `operate_at_root_group_level` and enabled groups/projects.
- CI/CD variables can now be created in multiple targets (root group, specific groups, or specific projects) depending on configuration.
- Output `gitlab_root_namespace_id` now returns `null` when not operating at root group level.

### Removed

- **BREAKING CHANGE**: variable `gitlab_agent_grant_access_to_entire_root_namespace` - replaced by `operate_at_root_group_level`.
- **BREAKING CHANGE**: variable `gitlab_agent_create_variables_in_root_namespace` - behavior is now determined by `operate_at_root_group_level`.
- Backward compatibility logic for deprecated variables.

### Migration Guide

If you were using the removed variables, migrate as follows:

- `gitlab_agent_grant_user_access_to_root_namespace = true` -> `operate_at_root_group_level = true` + `gitlab_agent_grant_user_access_to_root_namespace = true`
- `gitlab_agent_grant_access_to_entire_root_namespace = true` + `gitlab_agent_create_variables_in_root_namespace = true` → `operate_at_root_group_level = true` + `gitlab_agent_grant_user_access_to_root_namespace = true`
- `gitlab_agent_grant_access_to_entire_root_namespace = false` -> `operate_at_root_group_level = false` + configure `groups_enabled` and/or `projects_enabled`

**Note**: user access is now only available when `operate_at_root_group_level = true`. If you need user access to specific groups/projects, this is not currently supported by Gitlab.

## [0.12.0] - 2025-05-19

[Compare with previous version](https://github.com/sparkfabrik/terraform-gitlab-kubernetes-gitlab-agent/compare/0.11.0...0.12.0)

### Added

- Add the `gitlab_agent_deploy_enabled` variable to control whether to deploy the GitLab Agent components. When set to false, the module only creates the GitLab Agent token, Kubernetes namespace and secret without deploying the agent itself.

## [0.11.0] - 2025-04-15

[Compare with previous version](https://github.com/sparkfabrik/terraform-gitlab-kubernetes-gitlab-agent/compare/0.10.0...0.11.0)

### Changed

- Upgrade the default Helm chart to version `2.13.0`.

## [0.10.0] - 2025-04-13

[Compare with previous version](https://github.com/sparkfabrik/terraform-gitlab-kubernetes-gitlab-agent/compare/0.9.0...0.10.0)

### Changed

- Upgrade version gitlab-agent Helm chart to `2.11.0`.

## [0.9.0] - 2024-11-13

[Compare with previous version](https://github.com/sparkfabrik/terraform-gitlab-kubernetes-gitlab-agent/compare/0.8.0...0.9.0)

### Changed

- Upgrade the default Helm chart to version `2.8.3`.

## [0.8.0] - 2024-10-30

[Compare with previous version](https://github.com/sparkfabrik/terraform-gitlab-kubernetes-gitlab-agent/compare/0.7.0...0.8.0)

### Changed

- Upgrade the default Helm chart to version `2.8.2`.

## [0.7.0] - 2024-10-22

[Compare with previous version](https://github.com/sparkfabrik/terraform-gitlab-kubernetes-gitlab-agent/compare/0.6.0...0.7.0)

### Added

- The module can create the gitlab agents project by setting the variable `gitlab_project_name`.

## [0.6.0] - 2024-07-30

[Compare with previous version](https://github.com/sparkfabrik/terraform-gitlab-kubernetes-gitlab-agent/compare/0.5.0...0.6.0)

### Changed

- Upgrade the default Helm chart to version `2.6.2`.

## [0.5.0] - 2024-07-30

[Compare with previous version](https://github.com/sparkfabrik/terraform-gitlab-kubernetes-gitlab-agent/compare/0.4.0...0.5.0)

### Added

- Add the `gitlab_agent_grant_user_access_to_root_namespace` variable to grant the `user_access` permission on the root namespace.
- Upgrade the Helm chart to version `2.5.0` for Gitlab 17.

## [0.4.0] - 2024-07-10

[Compare with previous version](https://github.com/sparkfabrik/terraform-gitlab-kubernetes-gitlab-agent/compare/0.3.0...0.4.0)

### Added

- Add the `gitlab_agents_project_id` and `gitlab_root_namespace_id` outputs to allow the retrieval of the Gitlab project and root namespace IDs.

## [0.3.0] - 2024-07-10

[Compare with previous version](https://github.com/sparkfabrik/terraform-gitlab-kubernetes-gitlab-agent/compare/0.2.0...0.3.0)

### Added

- Add the `create_default_pod_anti_affinity` variable to allow the creation of the default podAntiAffinity rule in the helm values.

## [0.2.0] - 2024-07-04

[Compare with previous version](https://github.com/sparkfabrik/terraform-gitlab-kubernetes-gitlab-agent/compare/0.1.0...0.2.0)

### Added

- Add dependency on the Gitlab variables to prevent their creation before the helm release.
- Add the `gitlab_agent_append_to_config_file` variable to allow customizations to the agent configuration file keeping the access for the root namespace managed by the module.

## [0.1.0] - 2024-06-27

- First release.
