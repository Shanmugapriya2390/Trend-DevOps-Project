terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "trend_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "trend-vpc"
    Project = "Trend-DevOps"
  }
}

resource "aws_subnet" "trend_public_subnet" {
  vpc_id                  = aws_vpc.trend_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name    = "trend-public-subnet"
    Project = "Trend-DevOps"
  }
}

resource "aws_internet_gateway" "trend_igw" {
  vpc_id = aws_vpc.trend_vpc.id

  tags = {
    Name    = "trend-igw"
    Project = "Trend-DevOps"
  }
}

resource "aws_route_table" "trend_public_rt" {
  vpc_id = aws_vpc.trend_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.trend_igw.id
  }

  tags = {
    Name    = "trend-public-route-table"
    Project = "Trend-DevOps"
  }
}

resource "aws_route_table_association" "trend_public_rta" {
  subnet_id      = aws_subnet.trend_public_subnet.id
  route_table_id = aws_route_table.trend_public_rt.id
}

# IAM role that EC2 will use for Jenkins
resource "aws_iam_role" "jenkins_role" {
  name = "trend-jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = "Trend-DevOps"
  }
}

# Allow Jenkins to retrieve EKS cluster connection details.
# Kubernetes deployment permissions will be configured separately.
resource "aws_iam_role_policy" "jenkins_eks_describe" {
  name = "trend-jenkins-eks-describe"
  role = aws_iam_role.jenkins_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "trend-jenkins-instance-profile"
  role = aws_iam_role.jenkins_role.name

  tags = {
    Project = "Trend-DevOps"
  }
}

# Jenkins access: only the administrator's IP is allowed.
resource "aws_security_group" "jenkins_sg" {
  name        = "trend-jenkins-sg"
  description = "Restricted access for Jenkins and SSH"
  vpc_id      = aws_vpc.trend_vpc.id

  ingress {
    description = "Jenkins web dashboard from administrator IP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "SSH from administrator IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    description = "Outbound traffic for package downloads and deployments"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "trend-jenkins-sg"
    Project = "Trend-DevOps"
  }
}

# Retrieve the latest Ubuntu 24.04 LTS AMI for x86_64
data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/noble/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

# Jenkins EC2 server
resource "aws_instance" "jenkins_server" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = "t3.small"
  key_name                    = "trend-jenkins-key"
  subnet_id                   = aws_subnet.trend_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.jenkins_profile.name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name    = "trend-jenkins-server"
    Project = "Trend-DevOps"
  }
}
