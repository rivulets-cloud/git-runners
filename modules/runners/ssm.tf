# Parameter value is managed by the user-data script of the gitlab runner instance
resource "aws_ssm_parameter" "runner_registration_token" {
  name  = local.secure_parameter_store_runner_token_key
  type  = "SecureString"
  value = "null"

  tags = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}

# to read the current token for the null_resource. aws_ssm_parameter.runner_registration_token.value is never updated!
data "aws_ssm_parameter" "current_runner_registration_token" {
  depends_on = [aws_ssm_parameter.runner_registration_token]

  name = local.secure_parameter_store_runner_token_key
}

resource "null_resource" "remove_runner" {
  depends_on = [aws_ssm_parameter.runner_registration_token]

  triggers = {
    aws_region                = var.aws_region
    runners_gitlab_url        = var.runners_gitlab_url
    runner_registration_token = data.aws_ssm_parameter.current_runner_registration_token.value
  }

  provisioner "local-exec" {
    when       = destroy
    on_failure = continue
    command    = "curl -sS --request DELETE \"${self.triggers.runners_gitlab_url}/api/v4/runners\" --form \"token=${self.triggers.runner_registration_token}\""
  }
}

resource "aws_ssm_parameter" "runner_sentry_dsn" {
  name  = local.secure_parameter_store_runner_sentry_dsn
  type  = "SecureString"
  value = "null"

  tags = local.tags

  lifecycle {
    ignore_changes = [value]
  }
}