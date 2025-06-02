variable "project_name" {
  description = "Project name for resource naming."
  type        = string
  default     = "devops-david-site-project"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy resources."
  type        = string
  default     = "us-east-1"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for contact submissions."
  type        = string
  default     = "contactsubmission-devops-david-site-project"
} 