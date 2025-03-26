output "bucket_name" {
  value = module.rss_notification.bucket_name
}

output "sns_topic_arn" {
  value = module.rss_notification.sns_topic_arn
}

output "lambda_function_arn" {
  value = module.rss_notification.lambda_function_arn
}