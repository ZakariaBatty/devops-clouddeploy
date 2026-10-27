# CloudDeploy

CloudDeploy is an educational Master DevOps project demonstrating infrastructure, configuration management, containerization, and CI/CD.

The `CloudDeploy Local CD` workflow is an ephemeral deployment demonstration used while AWS access is pending. It builds and runs the CI-verified commit only on a temporary GitHub-hosted runner, verifies an HTTP `200` response, and then removes the container; it is not a persistent production deployment.
