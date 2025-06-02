resource "aws_dynamodb_table" "contact_submissions" {
  name         = var.dynamodb_table_name
  billing_mode = var.dynamodb_billing_mode
  hash_key     = var.dynamodb_hash_key

  attribute {
    name = var.dynamodb_hash_key
    type = var.dynamodb_hash_key_type
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "lambda_dynamodb_table_access" {
  name        = "${var.project_name}-lambda-dynamodb-table-access"
  description = "Least privilege: allow Lambda to access only the specific DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Resource = "arn:aws:dynamodb:${var.aws_region}:*:*table/${var.dynamodb_table_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_dynamodb_table_access.arn
}

resource "aws_iam_policy" "lambda_vpc_access" {
  name        = "${var.project_name}-lambda-vpc-access"
  description = "Allow Lambda to manage ENIs in VPC"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_vpc_access.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_security_group" "lambda_sg" {
  name        = "${var.project_name}-lambda-sg"
  description = "Least privilege security group for Lambda"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-lambda-sg"
  })
}

data "archive_file" "lambda_hello_world" {
  type        = "zip"
  source_file = "${path.module}/lamda/index.js"
  output_path = "${path.module}/hello-world.zip"
}

resource "aws_lambda_function" "main" {
  function_name = "${var.project_name}-lambda"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  filename      = data.archive_file.lambda_hello_world.output_path
  timeout       = 3
  memory_size   = 128

  environment {
    variables = {
      CONTACTS_TABLE_NAME = var.dynamodb_table_name
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.subnet_1.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  tags = local.common_tags
}

# --- API Gateway Integration for Lambda ---

resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = "${var.project_name}-api"
  description = "API Gateway for Lambda"
}

resource "aws_api_gateway_resource" "contact" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "contact"
}

resource "aws_api_gateway_method" "post_contact" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.contact.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_post" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_api.id
  resource_id             = aws_api_gateway_resource.contact.id
  http_method             = aws_api_gateway_method.post_contact.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main.invoke_arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.lambda_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "lambda_api" {
  depends_on = [
    aws_api_gateway_integration.lambda_post,
    aws_api_gateway_integration.options_contact,
    aws_api_gateway_method.options_contact,
    aws_api_gateway_method_response.options_contact,
    aws_api_gateway_integration_response.options_contact
  ]
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  deployment_id = aws_api_gateway_deployment.lambda_api.id
  stage_name    = "prod"
}

# --- CORS support for /contact resource ---
# Why: Browsers require CORS headers for cross-origin requests. Without an OPTIONS method and correct headers, browsers will block requests from your frontend (e.g., http://10.0.0.75:8080) to this API.

resource "aws_api_gateway_method" "options_contact" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.contact.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_contact" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_api.id
  resource_id             = aws_api_gateway_resource.contact.id
  http_method             = aws_api_gateway_method.options_contact.http_method
  type                    = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_contact" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.options_contact.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_contact" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.contact.id
  http_method = aws_api_gateway_method.options_contact.http_method
  status_code = aws_api_gateway_method_response.options_contact.status_code
  response_templates = {
    "application/json" = ""
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'" # Or your domain
  }
}

# --- API Gateway Integration for /newsletter ---

resource "aws_api_gateway_resource" "newsletter" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "newsletter"
}

resource "aws_api_gateway_method" "post_newsletter" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.newsletter.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_post_newsletter" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_api.id
  resource_id             = aws_api_gateway_resource.newsletter.id
  http_method             = aws_api_gateway_method.post_newsletter.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.newsletter.invoke_arn
}

# CORS for /newsletter OPTIONS
resource "aws_api_gateway_method" "options_newsletter" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.newsletter.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_newsletter" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_api.id
  resource_id             = aws_api_gateway_resource.newsletter.id
  http_method             = aws_api_gateway_method.options_newsletter.http_method
  type                    = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_newsletter" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.newsletter.id
  http_method = aws_api_gateway_method.options_newsletter.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_newsletter" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.newsletter.id
  http_method = aws_api_gateway_method.options_newsletter.http_method
  status_code = aws_api_gateway_method_response.options_newsletter.status_code
  response_templates = {
    "application/json" = ""
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Update deployment dependencies
data "aws_api_gateway_deployment" "lambda_api" {
  depends_on = [
    aws_api_gateway_integration.lambda_post,
    aws_api_gateway_integration.options_contact,
    aws_api_gateway_method.options_contact,
    aws_api_gateway_method_response.options_contact,
    aws_api_gateway_integration_response.options_contact,
    aws_api_gateway_integration.lambda_post_newsletter,
    aws_api_gateway_integration.options_newsletter,
    aws_api_gateway_method.options_newsletter,
    aws_api_gateway_method_response.options_newsletter,
    aws_api_gateway_integration_response.options_newsletter
  ]
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
}

# --- IAM Assume Role Policy for Newsletter Lambda ---
data "aws_iam_policy_document" "assume_role_newsletter" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# --- IAM Role for Newsletter Lambda ---
resource "aws_iam_role" "lambda_exec_newsletter" {
  name = "lambda_exec_newsletter_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_newsletter.json
}

# --- IAM Policy for Newsletter Lambda DynamoDB Access ---
resource "aws_iam_policy" "lambda_newsletter_dynamodb_access" {
  name        = "${var.project_name}-lambda-newsletter-dynamodb-access"
  description = "Allow Lambda to access the newsletter DynamoDB table"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ],
        Resource = "arn:aws:dynamodb:${var.aws_region}:*:table/${var.newsletter_table_name}"
      }
    ]
  })
}

# --- Attach Policy to Newsletter Lambda Role ---
resource "aws_iam_role_policy_attachment" "lambda_newsletter_dynamodb_access" {
  role       = aws_iam_role.lambda_exec_newsletter.name
  policy_arn = aws_iam_policy.lambda_newsletter_dynamodb_access.arn
}

# --- Attach Basic Execution Role for Logging ---
resource "aws_iam_role_policy_attachment" "lambda_newsletter_logging" {
  role       = aws_iam_role.lambda_exec_newsletter.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# --- Archive the Newsletter Lambda Code ---
data "archive_file" "lambda_newsletter" {
  type        = "zip"
  source_file = "${path.module}/lamda/index-newsletter.js"
  output_path = "${path.module}/newsletter.zip"
}

# --- Lambda Function for Newsletter ---
resource "aws_lambda_function" "newsletter" {
  function_name = "${var.project_name}-newsletter-lambda"
  role          = aws_iam_role.lambda_exec_newsletter.arn
  handler       = "index-newsletter.handler"
  runtime       = "nodejs18.x"
  filename      = data.archive_file.lambda_newsletter.output_path
  timeout       = 3
  memory_size   = 128

  environment {
    variables = {
      EMAILS_TABLE_NAME = var.newsletter_table_name
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.subnet_1.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  tags = local.common_tags
} 