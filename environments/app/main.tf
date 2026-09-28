terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "davidpoku-terraform-state-2026"
    key            = "environments/app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "davidpoku-terraform-state-2026"
    key    = "environments/network/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "App security group using shared network"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    description = "Allow SSH"
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

resource "aws_instance" "app" {
  ami                    = "ami-0c101f26f147fa7fd"
  instance_type          = "t3.micro"
  subnet_id              = data.terraform_remote_state.network.outputs.subnet_id
  vpc_security_group_ids = [aws_security_group.app.id]

  tags = {
    Name = "app-instance"
  }
}
