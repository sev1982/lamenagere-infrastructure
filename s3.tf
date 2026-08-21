# ── Bucket S3 pour les documents de vérification des prestataires ─────────────

resource "aws_s3_bucket" "documents" {
  bucket = "lamenagere-documents-${var.environnement}"
}

resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "documents" {
  bucket                  = aws_s3_bucket.documents.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Cycle de vie : supprimer les documents rejetés après 90 jours
resource "aws_s3_bucket_lifecycle_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    id     = "supprimer-rejetes"
    status = "Enabled"
    filter { prefix = "rejetes/" }
    expiration { days = 90 }
  }

  rule {
    id     = "archiver-anciens"
    status = "Enabled"
    filter { prefix = "approuves/" }
    transition {
      days          = 365
      storage_class = "STANDARD_IA"
    }
  }
}

# Politique : accès uniquement via CloudFront (Origin Access Control)
resource "aws_s3_bucket_policy" "documents" {
  bucket = aws_s3_bucket.documents.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.documents.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.documents.arn
          }
        }
      }
    ]
  })
}

# ── Bucket S3 pour les logs CloudFront ────────────────────────────────────────

resource "aws_s3_bucket" "logs" {
  bucket = "lamenagere-logs-${var.environnement}"
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule { object_ownership = "BucketOwnerPreferred" }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id     = "rotation-logs"
    status = "Enabled"
    filter {}
    expiration { days = 90 }
  }
}
