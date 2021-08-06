# Workflows

GitHub Actions workflows for your Enterprise instance go here.  Please don't use the ones in `~/.github/workflows` as those are the ones that run in this public repository.

:information_source:  Check the path of the Docker image and change it to what you'd like.

:closed_lock_with_key: These workflows assume you have some secrets stored in GitHub Secrets.

- `GHE_HOSTNAME` is the FQDN of your GHES server, such as `github.contoso.com`
- `GHE_USERNAME` is a service account on your GHES server that has permission to publish images.
- `GHE_TOKEN` is the personal access token for :point_up: service account.  It needs the following scopes:
  - `write:packages`
  - `delete:packages`
- `TEST_RUNNER_ACCOUNT` is the service account used in the testing `test-runners` namespace.
- `PROD_RUNNER_DEPLOY` is the service account used in the production `runners` namespace.
