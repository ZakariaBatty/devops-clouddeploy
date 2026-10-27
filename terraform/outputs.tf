output "instance_id" {
  description = "ID of the CloudDeploy EC2 instance."
  value       = aws_instance.clouddeploy.id
}

output "public_ip" {
  description = "Public IPv4 address of the CloudDeploy EC2 instance."
  value       = aws_instance.clouddeploy.public_ip
}

output "website_url" {
  description = "Public HTTP URL for the CloudDeploy website."
  value       = "http://${aws_instance.clouddeploy.public_ip}"
}
