terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name_prefix         = "${var.project_name}-${data.aws_caller_identity.current.account_id}"
  effective_subnet_id = var.subnet_id != null ? var.subnet_id : aws_subnet.lab[0].id
}

resource "aws_subnet" "lab" {
  count = var.subnet_id == null ? 1 : 0

  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = cidrsubnet(data.aws_vpc.default.cidr_block, 8, 10)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${local.name_prefix}-subnet"
  }
}

resource "aws_sns_topic" "cpu_alarm" {
  name = "${local.name_prefix}-cpu-alarm"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.cpu_alarm.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_security_group" "ec2" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "Minimal SG for the CloudWatch alarm lab"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ec2-sg"
  }
}

resource "aws_instance" "lab" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = local.effective_subnet_id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = var.associate_public_ip_address
  monitoring                  = true
  user_data                   = <<-EOF
    #!/bin/bash
    nohup bash -c 'while true; do :; done' >/dev/null 2>&1 &
    nohup bash -c 'while true; do :; done' >/dev/null 2>&1 &
  EOF

  tags = {
    Name = "${local.name_prefix}-cpu-source"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.name_prefix}-cpu-high"
  alarm_description   = "Send an email when EC2 CPU stays above 80% for 5 minutes"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.lab.id
  }

  alarm_actions = [aws_sns_topic.cpu_alarm.arn]
  ok_actions    = [aws_sns_topic.cpu_alarm.arn]
}
