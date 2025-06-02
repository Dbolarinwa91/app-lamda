terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "devops-statefile-david-site-project-123456"
    region = var.aws_region
    key    = "devops-statefile-david-site-project-123456/statefile-123456.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = merge(local.common_tags, {
    Name = local.vpc_name
  })
}

resource "aws_subnet" "subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/20"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, {
    Name = local.subnet_1
  })
}

resource "aws_subnet" "subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.16.0/20"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, {
    Name = local.subnet_2
  })
}

resource "aws_subnet" "subnet_3" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.32.0/20"
  availability_zone       = "us-east-1d"
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, {
    Name = local.subnet_3
  })
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
}

resource "aws_route_table_association" "subnet_1_association" {
  subnet_id      = aws_subnet.subnet_1.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "subnet_2_association" {
  subnet_id      = aws_subnet.subnet_2.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "subnet_3_association" {
  subnet_id      = aws_subnet.subnet_3.id
  route_table_id = aws_route_table.route_table.id
}

# Example S3 bucket module (commented out)
# module "s3_bucket" {
#   source = "terraform-aws-modules/s3-bucket/aws"
#   bucket = "devops-statefile-david-site-project-1234567"
#   acl    = "private"
#   force_destroy = false
#   control_object_ownership = true
#   object_ownership         = "ObjectWriter"
#   versioning = {
#     enabled = true
#   }
# } 