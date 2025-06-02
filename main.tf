terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "devops-statefile-david-site-project-123456"
    region = "us-east-1"
    key    = "devops-statefile-david-site-project-123456/statefile-123456.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
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