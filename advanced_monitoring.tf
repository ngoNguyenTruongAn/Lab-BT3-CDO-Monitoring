# =========================================================
# Bài 2: Cài đặt CloudWatch Agent
# =========================================================

# 1. IAM Role cho EC2
resource "aws_iam_role" "ec2_cloudwatch_role" {
  name = "${local.name_prefix}-ec2-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Gắn Policy CloudWatchAgentServerPolicy vào Role
resource "aws_iam_role_policy_attachment" "cw_agent_policy" {
  role       = aws_iam_role.ec2_cloudwatch_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# 3. Tạo Instance Profile để gắn vào EC2
resource "aws_iam_instance_profile" "ec2_cloudwatch_profile" {
  name = "${local.name_prefix}-ec2-cw-profile"
  role = aws_iam_role.ec2_cloudwatch_role.name
}


# =========================================================
# Bài 3: Cảnh báo đăng nhập tài khoản Root
# =========================================================

# 1. Tạo S3 Bucket lưu log cho CloudTrail
resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "${local.name_prefix}-cloudtrail-logs-${random_id.bucket_id.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_bucket.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# 2. Tạo CloudTrail
resource "aws_cloudtrail" "management_events" {
  name                          = "${local.name_prefix}-management-events"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket.id
  include_global_service_events = true
  is_multi_region_trail         = true

  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
}

# 3. Tạo EventBridge Rule bắt sự kiện Root Login
resource "aws_cloudwatch_event_rule" "root_login_alert" {
  name        = "${local.name_prefix}-root-login-alert"
  description = "Trigger an alert when the root account logs into the AWS Console"

  event_pattern = jsonencode({
    "detail-type" = ["AWS Console Sign In via CloudTrail"]
    "source"      = ["aws.signin"]
    "detail" = {
      "userIdentity" = {
        "type" = ["Root"]
      }
    }
  })
}

# 4. Gắn Target của EventBridge Rule vào SNS Topic
resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.root_login_alert.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.cpu_alarm.arn
}

# 5. Cập nhật SNS Topic Policy để cho phép EventBridge bắn log
resource "aws_sns_topic_policy" "cpu_alarm_policy" {
  arn = aws_sns_topic.cpu_alarm.arn

  policy = jsonencode({
    Version = "2008-10-17"
    Id      = "__default_policy_ID"
    Statement = [
      {
        Sid    = "DefaultOwnerPolicy"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "SNS:GetTopicAttributes",
          "SNS:SetTopicAttributes",
          "SNS:AddPermission",
          "SNS:RemovePermission",
          "SNS:DeleteTopic",
          "SNS:Subscribe",
          "SNS:ListSubscriptionsByTopic",
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.cpu_alarm.arn
        Condition = {
          StringEquals = {
            "AWS:SourceOwner" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.cpu_alarm.arn
      },
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.cpu_alarm.arn
      }
    ]
  })
}
