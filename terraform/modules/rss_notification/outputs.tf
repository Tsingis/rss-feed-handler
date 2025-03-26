output "bucket_name" {
  value = aws_s3_bucket.rss_feeds_bucket.bucket
}

output "sns_topic_arn" {
  value = aws_sns_topic.rss_topic.arn
}

output "lambda_function_arn" {
  value = aws_lambda_function.rss_handler.arn
}