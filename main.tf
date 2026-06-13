terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
      bucket = "lifting-log-terraform-state-210948569931-eu-north-1-an"
      key = "infrastructure/terraform.tfstate"
      region = "eu-north-1"
  }
}

provider "aws" {
  region = "eu-north-1"
}

resource "aws_security_group" "lifting_log_sg" {
  name        = "lifting-log-sg"
  description = "Allow web and SSH traffic"

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "lifting_log_server" {
  ami           = "ami-05ec2ffaee0a0e6d4"
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.lifting_log_sg.id]

  tags = {
    Name = "lifting-log-backend-prod"
  }
}