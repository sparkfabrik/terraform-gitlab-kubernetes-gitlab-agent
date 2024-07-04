# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2024-07-04

[Compare with previous version](https://github.com/sparkfabrik/terraform-gitlab-kubernetes-gitlab-agent/compare/0.1.0...0.2.0)

- Add dependency on the Gitlab variables to prevent their creation before the helm release.
- Add the `gitlab_agent_append_to_config_file` variable to allow customizations to the agent configuration file keeping the access for the root namespace managed by the module.

## [0.1.0] - 2024-06-27

- First release.
