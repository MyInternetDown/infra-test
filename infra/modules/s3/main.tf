resource "aws_s3_bucket" "this" {
  for_each = var.buckets

  bucket        = "${var.name_prefix}-${each.key}"
  force_destroy = each.value.force_destroy

  tags = merge(var.tags, {
    Name   = "${var.name_prefix}-${each.key}"
    Module = "s3"
  })
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = aws_s3_bucket.this

  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = aws_s3_bucket.this

  bucket = each.value.id

  versioning_configuration {
    status = var.buckets[each.key].versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  for_each = {
    for name, bucket in aws_s3_bucket.this : name => bucket
    if var.buckets[name].lifecycle_rules_enabled
  }

  bucket = each.value.id

  rule {
    id     = "retain-noncurrent-versions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
