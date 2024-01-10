# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN S3 BUCKET AND DYNAMODB TABLE TO USE AS A TERRAFORM BACKEND
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# This module is forked from https://github.com/gruntwork-io/intro-to-terraform/tree/master/s3-backend
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  region = "ap-south-1"
}

# ------------------------------------------------------------------------------
# CREATE THE S3 BUCKET
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  account_id    = data.aws_caller_identity.current.account_id
}

resource "aws_s3_bucket" "terraform_state" {
  # With account id, this S3 bucket names can be *globally* unique.
  bucket = "${local.account_id}-terraform-states"

  # Enable versioning so we can see the full revision history of our
  # state files
  versioning {
    enabled = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# ------------------------------------------------------------------------------
# CREATE THE DYNAMODB TABLE
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}



#---------------------------------------------------------------------------
# Create IAM Role
#--------------------------------------------------------------------------

resource "aws_iam_role_policy" "S3Policy" {
  name = "S3Policy"
  role = aws_iam_role.S3FullAccessRole.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "S3FullAccessRole" {
  name = "S3FullAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "s3-ec2-profile" {
  name = "s3-ec2-profile"
  role = aws_iam_role.S3FullAccessRole.name
}

#-----------------------------------------------------------------------------
# CREATE EC2 INSTANCE
#------------------------------------------------------------------------------

variable "vpc" {
  description = "The ID of the VPC"
  type        = string
}

variable "ssh-pub" {
  description = "public-key"
}

variable "ami" {
  description = "ami of the instance"
}

variable "keypair" {
  description = "keypair of server"
}

variable "subnet-id" {
  description = "network data for server"
}



resource "aws_security_group" "TargetServer-SG" {
  name        = "TargetServer-SG"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TargetServer-SG"
  }
}

resource "aws_instance" "app_server" {
  count         = 2
  ami           = var.ami
  instance_type = "t2.micro"
  key_name      = var.keypair
  subnet_id     = var.subnet-id
  security_groups = [aws_security_group.TargetServer-SG.id]
  iam_instance_profile = aws_iam_instance_profile.s3-ec2-profile.name
  user_data      =  <<EOF
	#!bin/bash
	sudo apt-get update
	sudo apt-get upgrade
	wget https://my-publickey.s3.ap-south-1.amazonaws.com/Public-key.sh
        cd /home/ubuntu/
	cat Public-key.sh >> /home/ubuntu/.ssh/authorized_keys 
	EOF

  tags = {
    Name = "TargetServers"
  }
}
