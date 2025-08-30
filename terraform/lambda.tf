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
      RSS_FEEDS_URLS      = var.rss_feeds_urls
      RSS_FEEDS_BUCKET    = aws_s3_bucket.rss_feeds_bucket.bucket
      RSS_FEEDS_TOPIC_ARN = aws_sns_topic.rss_feeds_topic.arn
      AWS_ACCOUNT_ID      = data.aws_caller_identity.current.account_id
    }
  }

  filename         = var.lambda_package_path
  source_code_hash = filebase64sha256(var.lambda_package_path)
}

resource "aws_cloudwatch_log_group" "rss_handler_logs" {
  name              = "/aws/lambda/rss-feeds-handler"
  retention_in_days = 90
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
          aws_s3_bucket.rss_feeds_bucket.arn,
        ]
      },
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.rss_feeds_topic.arn
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