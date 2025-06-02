locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }

  vpc_name    = "vpc-1-${var.project_name}"
  subnet_1    = "subnet_1-${var.project_name}"
  subnet_2    = "subnet_2-${var.project_name}"
  subnet_3    = "subnet_3-${var.project_name}"
} 