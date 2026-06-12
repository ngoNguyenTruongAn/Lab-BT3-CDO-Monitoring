variable "aws_region" {
  description = "AWS region to deploy the lab"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Prefix used for resource names"
  type        = string
  default     = "cloudwatch-sns-lab"
}

variable "alert_email" {
  description = "Email address that will receive SNS notifications"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the CPU source"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet for the EC2 instance. Use a default VPC subnet for the simplest setup."
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to assign a public IP to the lab EC2 instance"
  type        = bool
  default     = true
}
