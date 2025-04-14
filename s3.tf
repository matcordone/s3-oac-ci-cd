# Bucket for the website
resource "aws_s3_bucket" "website" {
  bucket = "${var.project_name}-${var.environment}-website"
}

# Enable static website hosting
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Ownership controls for the bucket
resource "aws_s3_bucket_ownership_controls" "website" {
  bucket = aws_s3_bucket.website.id
  
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Policy for the S3 buucket to allow CloudFront to access it and to block public access straight to the bucket
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}