resource "aws_iam_role_policy" "instance" {
  count  = var.enable_cloudwatch_logging ? 1 : 0
  name   = "${var.environment}-instance-role"
  role   = aws_iam_role.instance.name
  policy = templatefile("${path.module}/policies/instance-logging-policy.json", { arn_format = var.arn_format })
}

locals {
  logging_user_data = templatefile("${path.module}/template/logging.tpl",
    {
      log_group_name = format("%s-%s", var.log_group_name, var.environment)
  })
  kms_key          = aws_kms_key.default.arn
}

resource "aws_cloudwatch_log_group" "environment" {
  count             = var.enable_cloudwatch_logging ? 1 : 0
  name              = var.log_group_name
  retention_in_days = var.cloudwatch_logging_retention_in_days
  tags              = local.tags
  kms_key_id        = local.kms_key
}