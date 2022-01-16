################################################################################
### Trust policy
################################################################################
resource "aws_iam_instance_profile" "instance" {
  name = "${local.name_iam_objects}-instance"
  role = aws_iam_role.instance.name
  tags = local.tags
}

resource "aws_iam_role" "instance" {
  name                 = "${local.name_iam_objects}-instance"
  assume_role_policy   = length(var.instance_role_json) > 0 ? var.instance_role_json : templatefile("${path.module}/policies/instance-role-trust-policy.json", {})
  permissions_boundary = var.permissions_boundary == "" ? null : "${var.arn_format}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.permissions_boundary}"
  tags                 = merge(local.tags, var.role_tags)
}

################################################################################
### Policies for runner agent instance to create docker machines via spot req.
###
### iam:PassRole To pass the role from the agent to the docker machine runners
################################################################################
resource "aws_iam_policy" "instance_docker_machine_policy" {
  name        = "${local.name_iam_objects}-docker-machine"
  path        = "/"
  description = "Policy for docker machine."
  policy = templatefile("${path.module}/policies/instance-docker-machine-policy.json",
    {
      docker_machine_role_arn = aws_iam_role.docker_machine.arn
  })
  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "instance_docker_machine_policy" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.instance_docker_machine_policy.arn
}

################################################################################
### Policies for runner agent instance to allow connection via Session Manager
################################################################################
resource "aws_iam_policy" "instance_session_manager_policy" {
  count = var.enable_runner_ssm_access ? 1 : 0

  name        = "${local.name_iam_objects}-session-manager"
  path        = "/"
  description = "Policy session manager."
  policy      = templatefile("${path.module}/policies/instance-session-manager-policy.json", {})
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "instance_session_manager_policy" {
  count = var.enable_runner_ssm_access ? 1 : 0

  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.instance_session_manager_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "instance_session_manager_aws_managed" {
  count = var.enable_runner_ssm_access ? 1 : 0

  role       = aws_iam_role.instance.name
  policy_arn = "${var.arn_format}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

################################################################################
### Add user defined policies
################################################################################
resource "aws_iam_role_policy_attachment" "user_defined_policies" {
  count      = length(var.runner_iam_policy_arns)
  role       = aws_iam_role.instance.name
  policy_arn = var.runner_iam_policy_arns[count.index]
}

################################################################################
### Policy for the docker machine instance to access cache
################################################################################
resource "aws_iam_role_policy_attachment" "docker_machine_cache_instance" {
  count      = var.cache_bucket["create"] || lookup(var.cache_bucket, "policy", "") != "" ? 1 : 0
  role       = aws_iam_role.instance.name
  policy_arn = local.bucket_policy
}

################################################################################
### docker machine instance policy
################################################################################
resource "aws_iam_role" "docker_machine" {
  name                 = "${local.name_iam_objects}-docker-machine"
  assume_role_policy   = length(var.docker_machine_role_json) > 0 ? var.docker_machine_role_json : templatefile("${path.module}/policies/instance-role-trust-policy.json", {})
  permissions_boundary = var.permissions_boundary == "" ? null : "${var.arn_format}:iam::${data.aws_caller_identity.current.account_id}:policy/${var.permissions_boundary}"
  tags                 = local.tags
}

resource "aws_iam_instance_profile" "docker_machine" {
  name = "${local.name_iam_objects}-docker-machine"
  role = aws_iam_role.docker_machine.name
  tags = local.tags
}

################################################################################
### Add user defined policies
################################################################################
resource "aws_iam_role_policy_attachment" "docker_machine_user_defined_policies" {
  count      = length(var.docker_machine_iam_policy_arns)
  role       = aws_iam_role.docker_machine.name
  policy_arn = var.docker_machine_iam_policy_arns[count.index]
}

################################################################################
resource "aws_iam_role_policy_attachment" "docker_machine_session_manager_aws_managed" {
  count = var.enable_docker_machine_ssm_access ? 1 : 0

  role       = aws_iam_role.docker_machine.name
  policy_arn = "${var.arn_format}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

################################################################################
### Service linked policy, optional
################################################################################
resource "aws_iam_policy" "service_linked_role" {
  count = var.allow_iam_service_linked_role_creation ? 1 : 0

  name        = "${local.name_iam_objects}-service_linked_role"
  path        = "/"
  description = "Policy for creation of service linked roles."
  policy      = templatefile("${path.module}/policies/service-linked-role-create-policy.json", { arn_format = var.arn_format })
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "service_linked_role" {
  count = var.allow_iam_service_linked_role_creation ? 1 : 0

  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.service_linked_role[0].arn
}
resource "aws_iam_policy" "ssm" {
  count = var.enable_manage_gitlab_token ? 1 : 0

  name        = "${local.name_iam_objects}-ssm"
  path        = "/"
  description = "Policy for runner token param access via SSM"
  policy      = templatefile("${path.module}/policies/instance-secure-parameter-role-policy.json", { arn_format = var.arn_format })
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.enable_manage_gitlab_token ? 1 : 0

  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.ssm[0].arn
}