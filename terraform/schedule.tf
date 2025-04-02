resource "aws_scheduler_schedule" "rss_schedule" {
  name                         = "rss-feeds-schedule"
  schedule_expression          = "cron(0 7 * * ? *)"
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
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = aws_lambda_function.rss_handler.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_policy_attachment" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_policy.arn
}