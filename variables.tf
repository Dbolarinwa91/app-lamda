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

variable "dynamodb_billing_mode" {
  description = "Billing mode for DynamoDB table."
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dynamodb_hash_key" {
  description = "Hash key for DynamoDB table."
  type        = string
  default     = "id"
}

variable "dynamodb_hash_key_type" {
  description = "Type of the hash key attribute."
  type        = string
  default     = "S"
}

variable "dynamodb_phone_type" {
  description = "Type of the phone attribute in DynamoDB table."
  type        = string
  default     = "S"
}

variable "dynamodb_fullName_type" {
  description = "Type of the fullName attribute in DynamoDB table."
  type        = string
  default     = "S"
}

variable "dynamodb_email_type" {
  description = "Type of the email attribute in DynamoDB table."
  type        = string
  default     = "S"
}

variable "dynamodb_company_type" {
  description = "Type of the company attribute in DynamoDB table."
  type        = string
  default     = "S"
}

variable "dynamodb_message_type" {
  description = "Type of the message attribute in DynamoDB table."
  type        = string
  default     = "S"
}

variable "dynamodb_submittedAt_type" {
  description = "Type of the submittedAt attribute in DynamoDB table."
  type        = string
  default     = "S"
}

variable "dynamodb_status_type" {
  description = "Type of the status attribute in DynamoDB table."
  type        = string
  default     = "S"
}

variable "dynamodb_ipAddress_type" {
  description = "Type of the ipAddress attribute in DynamoDB table."
  type        = string
  default     = "S"
}

variable "dynamodb_userAgent_type" {
  description = "Type of the userAgent attribute in DynamoDB table."
  type        = string
  default     = "S"
}

variable "dynamodb_source_type" {
  description = "Type of the source attribute in DynamoDB table."
  type        = string
  default     = "S"
} 