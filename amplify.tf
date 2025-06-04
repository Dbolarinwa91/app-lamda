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
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.pulse_robot.id
  branch_name = "main"
  stage       = "DEVELOPMENT"
  enable_auto_build = true
} 