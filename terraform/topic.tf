resource "aws_sns_topic" "rss_feeds_topic" {
  name              = var.topic_name
  kms_master_key_id = null
}

resource "aws_sns_topic" "rss_feeds_alarm_topic" {
  name              = var.alarm_topic_name
  kms_master_key_id = null
}