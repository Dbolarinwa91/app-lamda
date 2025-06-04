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

output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.main.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.main.arn
}

output "api_gateway_rest_api_id" {
  description = "The ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.lambda_api.id
}

output "api_gateway_stage_name" {
  description = "The name of the API Gateway stage"
  value       = aws_api_gateway_stage.prod.stage_name
}

output "api_invoke_url" {
  description = "Invoke URL for the deployed API Gateway stage"
  value       = "https://${aws_api_gateway_rest_api.lambda_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/contact"
}

output "api_gateway_newsletter_resource_id" {
  description = "The ID of the API Gateway /newsletter resource"
  value       = aws_api_gateway_resource.newsletter.id
}

output "api_gateway_newsletter_post_method_id" {
  description = "The ID of the API Gateway POST method for /newsletter"
  value       = aws_api_gateway_method.post_newsletter.id
}

output "api_newsletter_invoke_url" {
  description = "Invoke URL for the /newsletter endpoint"
  value       = "https://${aws_api_gateway_rest_api.lambda_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/newsletter"
}

output "amplify_app_id" {
  description = "The ID of the Amplify app."
  value       = aws_amplify_app.pulse_robot.id
}

output "amplify_app_arn" {
  description = "The ARN of the Amplify app."
  value       = aws_amplify_app.pulse_robot.arn
}

output "amplify_staging_branch_url" {
  description = "The URL of the Amplify staging branch."
  value       = aws_amplify_branch.staging.web_url
}