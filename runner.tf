module "runner" {
  source = "./modules/runners/"

  aws_region  = data.aws_region.current.name
  environment = terraform.workspace

  vpc_id                   = data.aws_vpc.vpc.id
  subnet_ids_gitlab_runner = data.aws_subnet_ids.subnet_ids.ids
  subnet_id_runners        = element(tolist(data.aws_subnet_ids.subnet_ids.ids), 0)
  metrics_autoscaling      = ["GroupDesiredCapacity", "GroupInServiceCapacity"]

  runners_name             = local.runner_name
  runners_gitlab_url       = local.gitlab_url
  enable_runner_ssm_access = true

  instance_type = "t3a.large"

  kms_alias_name = local.kms_alias_name
  log_group_name = local.log_group_name

  #   gitlab_runner_security_group_ids = [data.aws_security_group.default.id]

  docker_machine_download_url   = "https://gitlab-docker-machine-downloads.s3.amazonaws.com/v0.16.2-gitlab.2/docker-machine"
  docker_machine_spot_price_bid = "on-demand-price"

  gitlab_runner_registration_config = {
    registration_token = local.registration_token
    tag_list           = "docker_spot_runner"
    description        = "runner default - auto"
    locked_to_project  = "true"
    run_untagged       = "false"
    maximum_timeout    = "3600"
  }

  tags = {
    "tf-aws-gitlab-runner:example"           = "runner-default"
    "tf-aws-gitlab-runner:instancelifecycle" = "spot:yes"
  }

  runners_privileged         = "true"
  runners_additional_volumes = ["/certs/client"]

  runners_volumes_tmpfs = [
    {
      volume  = "/var/opt/cache",
      options = "rw,noexec"
    }
  ]

  runners_services_volumes_tmpfs = [
    {
      volume  = "/var/lib/mysql",
      options = "rw,noexec"
    }
  ]

  # working 9 to 5 :)
  runners_machine_autoscaling = [
    {
      periods    = ["\"* * 0-9,17-23 * * mon-fri *\"", "\"* * * * * sat,sun *\""]
      idle_count = 0
      idle_time  = 60
      timezone   = local.timezone
    }
  ]

  runners_post_build_script = "\"echo 'single line'\""
}

resource "null_resource" "cancel_spot_requests" {
  # Cancel active and open spot requests, terminate instances
  triggers = {
    environment = terraform.workspace
  }

  provisioner "local-exec" {
    when    = destroy
    command = "./bin/cancel-spot-instances.sh ${self.triggers.environment}"
  }
}