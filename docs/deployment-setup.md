# CloudDeploy deployment setup

The `CloudDeploy CD` GitHub Actions workflow deploys the Dockerized website to an existing EC2 instance after the `CloudDeploy CI` workflow succeeds on a push to `main`. It can also be started manually from the `main` branch.

The deployment always checks out and builds the exact commit selected by the trusted event. A completed pull-request workflow cannot use production credentials.

## GitHub environment and secrets

Create a GitHub environment named `production`. Add the following environment secrets:

| Secret | Value |
| --- | --- |
| `EC2_HOST` | EC2 public DNS name or public IP address. |
| `EC2_USER` | SSH username configured by Ansible, normally `ubuntu`. |
| `EC2_SSH_PRIVATE_KEY` | Complete private key matching the EC2 key pair, including its header and footer. |
| `EC2_KNOWN_HOSTS` | Trusted, pinned OpenSSH `known_hosts` entry for `EC2_HOST`. |

Environment secrets limit credential availability to the deployment job. For an additional approval gate, configure required reviewers on the `production` environment if the repository plan supports it.

Never store the SSH private key in the repository, workflow, inventory, artifacts, or job output.

## Pin the EC2 SSH host key

Strict host-key checking protects the deployment from connecting to an impersonated server. Obtain the server's public SSH host key through a trusted channel, such as the EC2 console or a verified first connection. Confirm its fingerprint on the server:

```bash
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

Construct a standard `known_hosts` line using the exact host value stored in `EC2_HOST` and the verified public key. Store that complete line in `EC2_KNOWN_HOSTS`:

```text
your-ec2-host.example.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...
```

Do not populate the secret by blindly trusting `ssh-keyscan`; it retrieves a key but does not authenticate it. If the EC2 instance is replaced and its host key changes, verify the new fingerprint before updating the secret.

## Deployment sequence

The workflow performs these steps:

1. Accepts only a successful CI run created by a push to `main`, or a manual run launched from `main`.
2. Checks out the exact commit SHA associated with that event.
3. Builds and exports the Docker image on the GitHub runner.
4. Transfers the compressed image archive over host-verified SSH.
5. Loads and preflights the new image in a temporary container on EC2 loopback port `18080`.
6. Tags the current image as `clouddeploy:rollback`, replaces the `clouddeploy` container, and publishes it on port `80`.
7. Requires an HTTP `200` response from the new container.
8. Restarts the previous image if the replacement fails its startup or HTTP check.
9. Removes temporary image archives, SSH material, and the candidate container.

Deployment concurrency is limited to one production run at a time. Queued deployments are not cancelled midway.

## EC2 prerequisites

Before the first deployment:

- Terraform has created the instance and allows HTTP plus trusted SSH traffic.
- Ansible has installed and started Docker.
- The configured EC2 user belongs to the `docker` group and has reconnected since that membership was added.
- The EC2 root volume has enough free space for the transferred and loaded image.
- No unrelated service is using ports `80` or loopback port `18080`.

## Troubleshooting

### Host key verification failed

Confirm that `EC2_HOST` exactly matches the hostname or address in `EC2_KNOWN_HOSTS`. If the host was replaced, independently verify its new fingerprint before updating the secret.

### Permission denied over SSH

Check that `EC2_USER` is correct, the private key matches the instance key pair, and the security group permits port 22 from the GitHub-hosted runner. GitHub-hosted runner addresses change; a tightly restricted SSH rule may require a deliberate connectivity strategy.

### Docker permission denied

Run the Ansible playbook and reconnect the SSH session so the user's Docker group membership takes effect. Verify with `docker info` on the instance.

### Port 80 is already allocated

Identify the existing process or container using port 80. The workflow expects to manage a container named `clouddeploy` as the website service.

### HTTP verification failed

Inspect `docker logs clouddeploy` and `docker ps --all` on the instance. The workflow attempts to restore the previously running image when the final health check fails.

## One-day project limitations

This approach transfers the entire Docker image over SSH and briefly stops the old container during the port-80 switch. The rollback preserves the previous image but not custom runtime options or external state. A production platform would normally use an image registry, immutable releases, centralized logs, stronger network controls, and a zero-downtime deployment strategy.
