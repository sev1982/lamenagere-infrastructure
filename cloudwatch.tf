# ── CloudWatch — Monitoring et alertes ────────────────────────────────────────

# Topic SNS pour les alertes email
resource "aws_sns_topic" "alertes" {
  name = "lamenagere-alertes-${var.environnement}"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alertes.arn
  protocol  = "email"
  endpoint  = var.alerte_email
}

# ── Alarmes Lambda ────────────────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "lambda_erreurs" {
  alarm_name          = "lamenagere-lambda-rappel-erreurs"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Erreurs dans la Lambda de rappel"
  alarm_actions       = [aws_sns_topic.alertes.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.rappel.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_duree" {
  alarm_name          = "lamenagere-lambda-rappel-timeout"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Maximum"
  threshold           = 50000 # 50s sur un timeout de 60s
  alarm_description   = "Lambda rappel proche du timeout"
  alarm_actions       = [aws_sns_topic.alertes.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.rappel.function_name
  }
}

# Alarme WAF supprimée — SNS (ca-central-1) incompatible avec WAF (us-east-1)
# Métriques WAF visibles dans le dashboard CloudWatch ci-dessous

# Alarme SES bounce supprimée — Reputation.BounceRate n'est pas disponible
# via CloudWatch dans ca-central-1. Surveiller via la console SES directement.

# ── Dashboard CloudWatch ──────────────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "lamenagere" {
  dashboard_name = "lamenagere-${var.environnement}"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title   = "Lambda Rappel - Invocations / Erreurs"
          region  = var.aws_region
          period  = 300
          stat    = "Sum"
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.rappel.function_name],
            ["AWS/Lambda", "Errors",      "FunctionName", aws_lambda_function.rappel.function_name],
          ]
        }
      },
      {
        type = "metric"
        properties = {
          title   = "WAF - Requetes autorisees / bloquees"
          region  = "us-east-1"
          period  = 300
          stat    = "Sum"
          metrics = [
            ["AWS/WAFV2", "AllowedRequests", "WebACL", aws_wafv2_web_acl.app.name, "Region", "us-east-1", "Rule", "ALL"],
            ["AWS/WAFV2", "BlockedRequests", "WebACL", aws_wafv2_web_acl.app.name, "Region", "us-east-1", "Rule", "ALL"],
          ]
        }
      }
    ]
  })
}
