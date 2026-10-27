variable "aws_region" {
  description = "AWS region in which to create the CloudDeploy infrastructure."
  type        = string
  default     = "eu-north-1"
}

variable "instance_type" {
  description = "EC2 instance type. Choose an x86_64 type compatible with the Ubuntu AMI."
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair used for SSH access."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.key_pair_name)) > 0
    error_message = "key_pair_name must contain the name of an existing EC2 key pair."
  }
}

variable "ssh_allowed_cidr" {
  description = "Trusted public IPv4 CIDR allowed to connect over SSH, ideally a single address using /32."
  type        = string
  nullable    = false

  validation {
    condition = (
      can(cidrnetmask(var.ssh_allowed_cidr)) &&
      var.ssh_allowed_cidr != "0.0.0.0/0"
    )
    error_message = "ssh_allowed_cidr must be a valid IPv4 CIDR and cannot be 0.0.0.0/0."
  }
}
