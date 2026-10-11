output "aws_region" {
  description = "AWS region configured for this project"
  value       = var.aws_region
}

output "vpc_id" {
  description = "ID of the Trend VPC"
  value       = aws_vpc.trend_vpc.id
}

output "public_subnet_id" {
  description = "ID of the Trend public subnet"
  value       = aws_subnet.trend_public_subnet.id
}

output "jenkins_role_arn" {
  description = "IAM role ARN for the future Jenkins EC2 instance"
  value       = aws_iam_role.jenkins_role.arn
}

output "jenkins_security_group_id" {
  description = "Security group ID for the future Jenkins EC2 instance"
  value       = aws_security_group.jenkins_sg.id
}
output "jenkins_instance_id" {
  description = "ID of the Jenkins EC2 instance"
  value       = aws_instance.jenkins_server.id
}

output "jenkins_public_ip" {
  description = "Public IPv4 address of the Jenkins server"
  value       = aws_instance.jenkins_server.public_ip
}