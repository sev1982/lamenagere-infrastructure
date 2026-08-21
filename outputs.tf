output "s3_bucket_documents" {
  description = "Nom du bucket S3 pour les documents"
  value       = aws_s3_bucket.documents.bucket
}

output "cloudfront_url" {
  description = "URL CloudFront pour accéder aux documents"
  value       = "https://${aws_cloudfront_distribution.documents.domain_name}"
}

output "ses_dkim_tokens" {
  description = "Tokens DKIM à ajouter dans le DNS de votre domaine"
  value       = aws_sesv2_email_identity.domaine.dkim_signing_attributes[0].tokens
}

output "lambda_rappel_arn" {
  description = "ARN de la Lambda de rappel"
  value       = aws_lambda_function.rappel.arn
}

output "waf_arn" {
  description = "ARN du WAF (à associer à CloudFront)"
  value       = aws_wafv2_web_acl.app.arn
}

output "cloudwatch_dashboard_url" {
  description = "URL du dashboard CloudWatch"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=lamenagere-${var.environnement}"
}
