resource "aws_sns_topic" "rss_feeds_topic" {
  name              = var.topic_name
  kms_master_key_id = aws_kms_key.rss_feeds_sns_key.arn
}

resource "aws_kms_key" "rss_feeds_sns_key" {
  description         = "KMS key for SNS encryption"
  enable_key_rotation = true
}