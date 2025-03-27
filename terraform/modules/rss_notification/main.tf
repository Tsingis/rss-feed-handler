resource "aws_s3_bucket" "rss_feeds_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "rss_bucket_versioning" {
  bucket = aws_s3_bucket.rss_feeds_bucket.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "rss_bucket_encryption" {
  bucket = aws_s3_bucket.rss_feeds_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "rss_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.rss_feeds_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_sns_topic" "rss_topic" {
  name = var.topic_name
}

resource "aws_iam_role" "lambda_role" {
  name = "rss-feeds-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "lambda_policy" {
  name = "rss-feeds-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = [
          "${aws_s3_bucket.rss_feeds_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.rss_feeds_bucket.arn}",
        ]
      },
      {
        Effect = "Allow"
        Action = "sns:Publish"
        Resource = aws_sns_topic.rss_topic.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/rss-feeds-handler:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "rss_handler" {
  function_name = "rss-feeds-handler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.handler"
  runtime       = "python3.13"
  architectures = ["x86_64"]
  memory_size   = 256
  timeout       = 30
  publish       = false

  environment {
    variables = {
      RSS_FEED_URLS = var.rss_feeds_urls
      BUCKET_NAME   = aws_s3_bucket.rss_feeds_bucket.bucket
      SNS_TOPIC_ARN = aws_sns_topic.rss_topic.arn
    }
  }

  filename         = var.lambda_package_path
  source_code_hash = filebase64sha256(var.lambda_package_path)
}

resource "aws_cloudwatch_log_group" "rss_handler_logs" {
  name              = "/aws/lambda/rss-feeds-handler"
  retention_in_days = 90
}

resource "aws_iam_role" "scheduler_role" {
  name = "rss-feeds-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "scheduler_policy" {
  name = "rss-feeds-scheduler-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = aws_lambda_function.rss_handler.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_policy_attachment" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_policy.arn
}

resource "aws_scheduler_schedule" "rss_schedule" {
  name                        = "rss-feeds-schedule"
  schedule_expression         = "cron(0 7 * * ? *)"
  schedule_expression_timezone = "Europe/Helsinki"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.rss_handler.arn
    role_arn = aws_iam_role.scheduler_role.arn

    retry_policy {
      maximum_retry_attempts       = 1
      maximum_event_age_in_seconds = 900
    }
  }
}