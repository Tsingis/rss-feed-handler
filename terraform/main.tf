provider "aws" {
  region = "eu-north-1"
}

module "rss_notification" {
  source              = "./modules/rss_notification"
  bucket_name         = var.bucket_name
  topic_name          = var.topic_name
  rss_feeds_urls      = var.rss_feeds_urls
  lambda_package_path = var.lambda_package_path
}