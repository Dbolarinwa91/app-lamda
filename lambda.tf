resource "aws_dynamodb_table" "contact_submissions" {
  name         = var.dynamodb_table_name
  billing_mode = var.dynamodb_billing_mode
  hash_key     = var.dynamodb_hash_key

  attribute {
    name = var.dynamodb_hash_key
    type = var.dynamodb_hash_key_type
  }
  attribute {
    name = "fullName"
    type = var.dynamodb_fullName_type
  }
  attribute {
    name = "email"
    type = var.dynamodb_email_type
  }
  attribute {
    name = "company"
    type = var.dynamodb_company_type
  }
  attribute {
    name = "phone"
    type = var.dynamodb_phone_type
  }
  attribute {
    name = "message"
    type = var.dynamodb_message_type
  }
  attribute {
    name = "submittedAt"
    type = var.dynamodb_submittedAt_type
  }
  attribute {
    name = "status"
    type = var.dynamodb_status_type
  }
  attribute {
    name = "ipAddress"
    type = var.dynamodb_ipAddress_type
  }
  attribute {
    name = "userAgent"
    type = var.dynamodb_userAgent_type
  }
  attribute {
    name = "source"
    type = var.dynamodb_source_type
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
} 