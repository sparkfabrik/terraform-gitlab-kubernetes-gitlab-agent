# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
