output "bucket_name" {
  value     = module.rss_notification.bucket_name
  sensitive = true
}

output "sns_topic_arn" {
  value     = module.rss_notification.sns_topic_arn
  sensitive = true
}

output "lambda_function_arn" {
  value     = module.rss_notification.lambda_function_arn
  sensitive = true
}