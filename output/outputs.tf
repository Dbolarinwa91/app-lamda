output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "The IDs of the subnets"
  value       = [aws_subnet.subnet_1.id, aws_subnet.subnet_2.id, aws_subnet.subnet_3.id]
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table."
  value       = aws_dynamodb_table.contact_submissions.name
}

output "dynamodb_billing_mode" {
  description = "The billing mode of the DynamoDB table."
  value       = aws_dynamodb_table.contact_submissions.billing_mode
}

output "dynamodb_hash_key" {
  description = "The hash key of the DynamoDB table."
  value       = aws_dynamodb_table.contact_submissions.hash_key
} 