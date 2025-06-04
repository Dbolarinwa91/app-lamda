resource "aws_amplify_app" "pulse_robot" {
  name         = "pulse-robot-template-39"
  repository   = "https://github.com/Dbolarinwa91/pulse-robot-template-39.git"
  oauth_token  = var.github_token
  platform     = "WEB"
  enable_branch_auto_build = true
}

resource "aws_amplify_branch" "staging" {
  app_id      = aws_amplify_app.pulse_robot.id
  branch_name = "staging"
  stage       = "STAGING"
  enable_auto_build = true
} 