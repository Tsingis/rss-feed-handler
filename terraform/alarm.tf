resource "aws_cloudwatch_log_metric_filter" "rss_feeds_metric_filter" {
  name           = "rss-feeds-metric-filter"
  log_group_name = aws_cloudwatch_log_group.rss_handler_logs.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "rss-feeds-error-metric"
    namespace = "rss-feeds/errors"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "rss_feeds_logs_alarm" {
  alarm_name          = "rss-feeds-alarm"
  alarm_description   = "Email notifications for lambda errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 0
  period              = 10
  statistic           = "SampleCount"
  treat_missing_data  = "missing"

  metric_name = aws_cloudwatch_log_metric_filter.rss_feeds_metric_filter.metric_transformation[0].name
  namespace   = aws_cloudwatch_log_metric_filter.rss_feeds_metric_filter.metric_transformation[0].namespace

  alarm_actions = [
    "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_sns_topic.rss_feeds_alarm_topic.name}"
  ]
}
