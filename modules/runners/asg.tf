resource "aws_autoscaling_group" "gitlab_runner_instance" {
  name                      = var.enable_asg_recreation ? "${aws_launch_template.gitlab_runner_instance.name}-asg" : "${var.environment}-as-group"
  vpc_zone_identifier       = var.subnet_ids_gitlab_runner
  min_size                  = "1"
  max_size                  = "1"
  desired_capacity          = "1"
  health_check_grace_period = 0
  max_instance_lifetime     = var.asg_max_instance_lifetime
  enabled_metrics           = var.metrics_autoscaling
  tags                      = local.agent_tags_propagated

  launch_template {
    id      = aws_launch_template.gitlab_runner_instance.id
    version = aws_launch_template.gitlab_runner_instance.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
    }
    triggers = ["tag"]
  }

  timeouts {
    delete = var.asg_delete_timeout
  }
}

resource "aws_autoscaling_schedule" "scale_in" {
  count                  = var.enable_schedule ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.gitlab_runner_instance.name
  scheduled_action_name  = "scale_in-${aws_autoscaling_group.gitlab_runner_instance.name}"
  recurrence             = var.schedule_config["scale_in_recurrence"]
  min_size               = var.schedule_config["scale_in_count"]
  desired_capacity       = var.schedule_config["scale_in_count"]
  max_size               = var.schedule_config["scale_in_count"]
}

resource "aws_autoscaling_schedule" "scale_out" {
  count                  = var.enable_schedule ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.gitlab_runner_instance.name
  scheduled_action_name  = "scale_out-${aws_autoscaling_group.gitlab_runner_instance.name}"
  recurrence             = var.schedule_config["scale_out_recurrence"]
  min_size               = var.schedule_config["scale_out_count"]
  desired_capacity       = var.schedule_config["scale_out_count"]
  max_size               = var.schedule_config["scale_out_count"]
}

resource "aws_launch_template" "gitlab_runner_instance" {
  name_prefix            = local.name_runner_agent_instance
  image_id               = data.aws_ami.runner.id
  user_data              = base64encode(local.template_user_data)
  instance_type          = var.instance_type
  update_default_version = true
  ebs_optimized          = var.runner_instance_ebs_optimized
  key_name                      = "rivulets-cloud-1"
  monitoring {
    enabled = var.runner_instance_enable_monitoring
  }
  # dynamic "instance_market_options" {
  #   for_each = var.runner_instance_spot_price == null || var.runner_instance_spot_price == "" ? [] : ["spot"]
  #   content {
  #     market_type = instance_market_options.value
  #     spot_options {
  #       max_price = var.runner_instance_spot_price == "on-demand-price" ? "" : var.runner_instance_spot_price
  #     }
  #   }
  # }

   instance_market_options {
    market_type = "spot"
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.instance.name
  }
  dynamic "block_device_mappings" {
    for_each = [var.runner_root_block_device]
    content {
      device_name = lookup(block_device_mappings.value, "device_name", "/dev/xvda")
      ebs {
        delete_on_termination = lookup(block_device_mappings.value, "delete_on_termination", true)
        volume_type           = lookup(block_device_mappings.value, "volume_type", "gp3")
        volume_size           = lookup(block_device_mappings.value, "volume_size", 8)
        encrypted             = lookup(block_device_mappings.value, "encrypted", true)
        iops                  = lookup(block_device_mappings.value, "iops", null)
        throughput            = lookup(block_device_mappings.value, "throughput", null)
        kms_key_id            = lookup(block_device_mappings.value, "kms_key_id", null)
      }
    }
  }
  network_interfaces {
    security_groups             = concat([aws_security_group.runner.id], var.extra_security_group_ids_runner_agent)
    # associate_public_ip_address = false == (var.runner_agent_uses_private_address == false ? var.runner_agent_uses_private_address : var.runners_use_private_address)
    associate_public_ip_address = true
  }
  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }
  tag_specifications {
    resource_type = "volume"
    tags          = local.tags
  }
  dynamic "tag_specifications" {
    for_each = var.runner_instance_spot_price == null || var.runner_instance_spot_price == "" ? [] : ["spot"]
    content {
      resource_type = "spot-instances-request"
      tags          = local.tags
    }
  }

  tags = local.tags

  metadata_options {
    http_endpoint = var.runner_instance_metadata_options_http_endpoint
    http_tokens   = var.runner_instance_metadata_options_http_tokens
  }

  lifecycle {
    create_before_destroy = true
  }
}
