## PRODUCER S3
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "aws_s3_bucket" "logstoragebucket" {
  bucket        = "drewpyslogstorebuck-${random_string.suffix.result}"
  force_destroy = true

  tags = {
    Name = "log-storage"
  }
}


resource "aws_s3_bucket_ownership_controls" "logstoragebucket_ownership" {
  bucket   = aws_s3_bucket.logstoragebucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  depends_on = [aws_s3_bucket.logstoragebucket]
}

resource "aws_s3_bucket_public_access_block" "logstoragebucket_public_access" {
  bucket = aws_s3_bucket.logstoragebucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "logstoragebucket_policy" {
  bucket = aws_s3_bucket.logstoragebucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "logs.amazonaws.com"
        },
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ],
        Resource = [
          "${aws_s3_bucket.logstoragebucket.arn}/*",
          "${aws_s3_bucket.logstoragebucket.arn}"
        ],
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "602484972838"
          },
          ArnLike = {
            "aws:SourceArn" = "arn:aws:logs:us-east-1:602484972838:log-group:*"
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket.logstoragebucket,
    aws_s3_bucket_ownership_controls.logstoragebucket_ownership,
  ]
}
