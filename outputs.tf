output "sns_topic_arn" {
  value       = aws_sns_topic.cpu_alarm.arn
  description = "SNS topic ARN for the CPU alarm"
}

output "ec2_instance_id" {
  value       = aws_instance.lab.id
  description = "EC2 instance used to generate CPU load"
}

output "ec2_public_ip" {
  value       = aws_instance.lab.public_ip
  description = "Public IP of the lab instance, if assigned"
}
