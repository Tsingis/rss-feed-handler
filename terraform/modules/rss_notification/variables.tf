variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "topic_name" {
  description = "Name of the SNS topic"
  type        = string
}

variable "rss_feeds_urls" {
  description = "Semicolon-separated list of RSS feeds URLs"
  type        = string
}

variable "lambda_package_path" {
  description = "Path to the Lambda deployment package"
  type        = string
}