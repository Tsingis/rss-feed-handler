resource "aws_s3_bucket" "rss_feeds_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "rss_bucket_versioning" {
  bucket = aws_s3_bucket.rss_feeds_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "rss_bucket_lifecycle" {
  bucket = aws_s3_bucket.rss_feeds_bucket.id

  rule {
    id     = "delete-old-files"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "rss_bucket_encryption" {
  bucket = aws_s3_bucket.rss_feeds_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "rss_bucket_public_access_block" {
  bucket                  = aws_s3_bucket.rss_feeds_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}