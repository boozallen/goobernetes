# Kubernetes roles

This folder contains additional YAML files to apply if you'd like, and what they do.

## Service accounts

These accounts exist in the Kubernetes cluster for GitHub Actions to use to deploy itself.  You'll take the `kubeconfig` file for each account, then encode it for storage in GitHub Secrets.  There are two, one for each namespace we created for the runners.

- `test-deploy-user.yml`
- `prod-deploy-user.yml`

You use these by copying them to the server and running the commands below as the user account you created to manage Kubernetes.

```shell
kubectl apply -f test-deploy-user.yml
kubectl apply -f prod-deploy-user.yml
```
