output "bucket_name" {
  value     = aws_s3_bucket.rss_feeds_bucket.bucket
  sensitive = true
}

output "sns_topic_arn" {
  value     = aws_sns_topic.rss_feeds_topic.arn
  sensitive = true
}

output "lambda_function_arn" {
  value     = aws_lambda_function.rss_handler.arn
  sensitive = true
}