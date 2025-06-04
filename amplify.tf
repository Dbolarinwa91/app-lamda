resource "aws_amplify_app" "pulse_robot" {
  name         = "pulse-robot-template-39"
  repository   = "https://github.com/Dbolarinwa91/pulse-robot-template-39.git"
  oauth_token  = var.github_token
  platform     = "WEB"
  enable_branch_auto_build = true

  environment_variables = {
    VITE_CONTACT_API_URL       = "https://${aws_api_gateway_rest_api.lambda_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/contact"
    VITE_NEWSLETTER_API_URL = "https://${aws_api_gateway_rest_api.lambda_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/newsletter"
  }

  # Add build settings
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: dist
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  # Enable branch auto-deletion
  enable_branch_auto_deletion = true
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.pulse_robot.id
  branch_name = "main"
  stage       = "DEVELOPMENT"
  enable_auto_build = true

  # Add build settings for the branch
  framework = "React"  # or whatever framework you're using

  # Add environment variables specific to this branch if needed
  environment_variables = {
    NODE_ENV = "development"
  }
} 