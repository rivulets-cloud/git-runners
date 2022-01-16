locals {
  runner_name        = "Gitlab-runner"
  gitlab_url         = "http://gitlab.rivulets.co.in"
  registration_token = "YDkJWQAVG-ZF_phP-Ufo"
  timezone           = "Asia/Calcutta"
  vpc_name = {
    nonprod = "dc-mgmt-nonprod"
    prod    = "dc-mgmt-prod"
  }

  subnet_name = {
    nonprod = "dc-mgmt-nonprod*"
    prod    = "dc-mgmt-prod*"
  }
  log_group_name = "gitlab-runner"
  kms_alias_name = "gitlab-runner"
  image_id       = data.aws_ami.ami.id
}