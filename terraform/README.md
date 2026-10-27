# CloudDeploy Terraform infrastructure

This directory defines the small AWS foundation for the CloudDeploy learning project:

- the default VPC and one of its existing subnets;
- one Ubuntu 24.04 LTS EC2 instance with a public IPv4 address;
- one security group allowing public HTTP and SSH from one trusted IPv4 CIDR;
- an existing EC2 key pair for SSH authentication.

Terraform resolves the latest matching official Ubuntu image published by Canonical at plan time. The default `t3.micro` instance type uses the image's x86_64 architecture.

## Files

| File | Purpose |
| --- | --- |
| `providers.tf` | Sets the Terraform and AWS provider requirements and selects the configured region. |
| `variables.tf` | Declares the region, instance type, existing key pair, and trusted SSH CIDR inputs. |
| `main.tf` | Looks up the default network and Ubuntu AMI, then defines the security group and EC2 instance. |
| `outputs.tf` | Exposes the instance ID, public IP address, and website URL. |
| `terraform.tfvars.example` | Provides safe example input values to copy and customize locally. |

## Local workflow

Prerequisites are Terraform, an AWS account, an existing EC2 key pair in the target region, and AWS credentials supplied through a standard external mechanism. Credentials and private keys must never be placed in Terraform files.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Replace `key_pair_name` with an existing key pair and `ssh_allowed_cidr` with your trusted public IPv4 address followed by `/32`. The configuration rejects `0.0.0.0/0` for SSH.

The safe local checks are:

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
```

When credentials and variables are ready, inspect changes with `terraform plan`. Do not apply a plan until you understand its cost and security impact.

## Cost and state notes

An EC2 instance, its EBS storage, and its public IPv4 address can incur AWS charges, even for a small learning environment. Review current AWS pricing and remove resources when they are no longer required.

This exercise intentionally keeps Terraform state local. Local state is ignored by Git and can contain sensitive infrastructure data. A secured remote backend with encryption, locking, access control, and versioning is preferable for team or production use.
