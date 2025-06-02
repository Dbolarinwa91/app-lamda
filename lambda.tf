resource "aws_dynamodb_table" "contact_submissions" {
  name         = "ContactSubmissions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_lambda_function" "contact_submission" {
  function_name = "contactSubmissionHandler"
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  # TODO: Update the following with your actual deployment package location
  filename         = "lambda/contactSubmission.zip"
  source_code_hash = filebase64sha256("lambda/contactSubmission.zip")

  role = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      CONTACTS_TABLE_NAME = aws_dynamodb_table.contact_submissions.name
    }
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