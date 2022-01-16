data "aws_caller_identity" "current" {}

data "aws_region" "current" {
}


data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [lookup(local.vpc_name, terraform.workspace)]
  }
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = [lookup(local.subnet_name, terraform.workspace)]
  }
}

data "aws_ami" "ami" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}