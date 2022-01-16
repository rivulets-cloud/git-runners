terraform {
  backend "s3" {
    key            = "gitlab/gitlab-runner.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "sftp-terraform-state-lock"
  }
}