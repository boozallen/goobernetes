# Runner deployments #

This folder contains all the deployment files for the Kubernetes cluster.

:warning:  You will need to edit each of these files to point to the appropriate image and enterprise name!

- `rawhide-*` deployments are not generally available to users.  These are deployed on a case-by-case basis to troubleshoot issues in production and if user input is needed, we'll direct you to target one of these nodes.  They start out identical to the production deployment and go on the same cluster.
- `test-*` deployments are for automated testing.  These build and deploy the latest `*-test` image, then run tests before merging into the main branch.
- `*-deployment` is the production deployment for each file type.
