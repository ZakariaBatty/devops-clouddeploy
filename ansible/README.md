# CloudDeploy server configuration

This directory contains the Ansible configuration for preparing the Ubuntu 24.04 EC2 host. It installs Docker Engine from Ubuntu's package repositories, starts the Docker service, adds the SSH user to the `docker` group, and installs a few basic deployment utilities.

The playbook configures the server only. Building, transferring, and running the CloudDeploy application container remains a separate deployment responsibility for a later GitHub Actions CD workflow.

## Terraform and Ansible

Terraform provisions infrastructure: the EC2 instance, network placement, security group, and public IP address. Ansible configures the operating system after that infrastructure exists: packages, services, and user permissions.

In short, Terraform creates the server; Ansible prepares the server.

## Files

| File | Purpose |
| --- | --- |
| `playbook.yml` | Idempotently installs utilities and Docker, manages its service, and grants the SSH user Docker access. |
| `inventory.ini.example` | Shows the required `webservers` inventory group and an example EC2 address. |
| `ansible.cfg` | Supplies safe project defaults, including the default `ubuntu` SSH user. |
| `README.md` | Documents configuration, usage, and verification. |

## Prepare the inventory

After Terraform has provisioned the instance, obtain its address:

```bash
cd terraform
terraform output -raw public_ip
```

Copy the example inventory and replace `203.0.113.10` with that output:

```bash
cp ansible/inventory.ini.example ansible/inventory.ini
```

The generated `ansible/inventory.ini` is ignored by Git. The SSH username defaults to `ubuntu`; change `ansible_user` in the inventory or pass `--user` if the image uses a different account.

Keep the SSH private key outside this repository with restrictive file permissions. Do not copy a private key into source control.

## Run the playbook

After the EC2 instance is running and SSH port 22 permits your trusted IP, run Ansible from its project directory so it automatically loads `ansible.cfg`:

```bash
cd ansible
ansible-playbook \
  --inventory inventory.ini \
  --private-key ~/.ssh/your-ec2-key.pem \
  playbook.yml
```

The first run installs and configures the packages. Later runs are idempotent and should report no changes when the server already matches the playbook. Group membership is applied to new login sessions, so reconnect over SSH before running Docker without `sudo`.

## Verify Docker

Reconnect to the instance using the external private key, then run:

```bash
docker --version
docker info
systemctl is-enabled docker
systemctl is-active docker
```

Expected results are a Docker version, accessible Docker daemon information, and `enabled` plus `active` service states.

## Local checks

The playbook can be parsed locally without contacting the example host:

```bash
ansible-playbook --syntax-check -i ansible/inventory.ini.example ansible/playbook.yml
```
