locals {
  template_user_data = templatefile("${path.module}/template/user-data.tpl",
    {
      eip                 = ""
      logging             = var.enable_cloudwatch_logging ? local.logging_user_data : ""
      gitlab_runner       = local.template_gitlab_runner
      user_data_trace_log = var.enable_runner_user_data_trace_log
  })

  template_gitlab_runner = templatefile("${path.module}/template/gitlab-runner.tpl",
    {
      gitlab_runner_version                        = var.gitlab_runner_version
      docker_machine_version                       = var.docker_machine_version
      docker_machine_download_url                  = var.docker_machine_download_url
      runners_config                               = local.template_runner_config
      runners_executor                             = var.runners_executor
      runners_install_amazon_ecr_credential_helper = var.runners_install_amazon_ecr_credential_helper
      pre_install                                  = var.userdata_pre_install
      post_install                                 = var.userdata_post_install
      runners_gitlab_url                           = var.runners_gitlab_url
      runners_token                                = var.runners_token
      secure_parameter_store_runner_token_key      = local.secure_parameter_store_runner_token_key
      secure_parameter_store_runner_sentry_dsn     = local.secure_parameter_store_runner_sentry_dsn
      secure_parameter_store_region                = var.aws_region
      gitlab_runner_registration_token             = var.gitlab_runner_registration_config["registration_token"]
      giltab_runner_description                    = var.gitlab_runner_registration_config["description"]
      gitlab_runner_tag_list                       = var.gitlab_runner_registration_config["tag_list"]
      gitlab_runner_locked_to_project              = var.gitlab_runner_registration_config["locked_to_project"]
      gitlab_runner_run_untagged                   = var.gitlab_runner_registration_config["run_untagged"]
      gitlab_runner_maximum_timeout                = var.gitlab_runner_registration_config["maximum_timeout"]
      gitlab_runner_access_level                   = lookup(var.gitlab_runner_registration_config, "access_level", "not_protected")
      sentry_dsn                                   = var.sentry_dsn
  })

  template_runner_config = templatefile("${path.module}/template/runner-config.tpl",
    {
      aws_region                  = var.aws_region
      gitlab_url                  = var.runners_gitlab_url
      runners_vpc_id              = var.vpc_id
      runners_subnet_id           = var.subnet_id_runners
      runners_aws_zone            = data.aws_availability_zone.runners.name_suffix
      runners_instance_type       = var.docker_machine_instance_type
      runners_spot_price_bid      = var.docker_machine_spot_price_bid == "on-demand-price" ? "" : var.docker_machine_spot_price_bid
      runners_ami                 = data.aws_ami.docker-machine.id
      runners_security_group_name = aws_security_group.docker_machine.name
      runners_monitoring          = var.runners_monitoring
      runners_ebs_optimized       = var.runners_ebs_optimized
      runners_instance_profile    = aws_iam_instance_profile.docker_machine.name
      runners_additional_volumes  = local.runners_additional_volumes
      docker_machine_options      = length(local.docker_machine_options_string) == 1 ? "" : local.docker_machine_options_string
      runners_name                = var.runners_name
      runners_tags = replace(var.overrides["name_docker_machine_runners"] == "" ? format(
        "Name,%s-docker-machine,%s,%s",
        var.environment,
        local.tags_string,
        local.runner_tags_string,
        ) : format(
        "%s,%s,Name,%s",
        local.tags_string,
        local.runner_tags_string,
        var.overrides["name_docker_machine_runners"],
      ), ",,", ",")
      runners_token                     = var.runners_token
      runners_executor                  = var.runners_executor
      runners_limit                     = var.runners_limit
      runners_concurrent                = var.runners_concurrent
      runners_image                     = var.runners_image
      runners_privileged                = var.runners_privileged
      runners_disable_cache             = var.runners_disable_cache
      runners_docker_runtime            = var.runners_docker_runtime
      runners_helper_image              = var.runners_helper_image
      runners_shm_size                  = var.runners_shm_size
      runners_pull_policy               = var.runners_pull_policy
      runners_idle_count                = var.runners_idle_count
      runners_idle_time                 = var.runners_idle_time
      runners_max_builds                = local.runners_max_builds_string
      runners_machine_autoscaling       = local.runners_machine_autoscaling
      runners_root_size                 = var.runners_root_size
      runners_iam_instance_profile_name = var.runners_iam_instance_profile_name
      runners_use_private_address_only  = var.runners_use_private_address
      runners_use_private_address       = !var.runners_use_private_address
      runners_request_spot_instance     = var.runners_request_spot_instance
      runners_environment_vars          = jsonencode(var.runners_environment_vars)
      runners_pre_build_script          = var.runners_pre_build_script
      runners_post_build_script         = var.runners_post_build_script
      runners_pre_clone_script          = var.runners_pre_clone_script
      runners_request_concurrency       = var.runners_request_concurrency
      runners_output_limit              = var.runners_output_limit
      runners_check_interval            = var.runners_check_interval
      runners_volumes_tmpfs             = join(",", [for v in var.runners_volumes_tmpfs : format("\"%s\" = \"%s\"", v.volume, v.options)])
      runners_services_volumes_tmpfs    = join(",", [for v in var.runners_services_volumes_tmpfs : format("\"%s\" = \"%s\"", v.volume, v.options)])
      bucket_name                       = local.bucket_name
      shared_cache                      = var.cache_shared
      sentry_dsn                        = var.sentry_dsn
    }
  )
}