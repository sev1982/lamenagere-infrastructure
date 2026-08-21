# ── AWS WAF v2 — Protection de l'application ──────────────────────────────────
# Déployé en us-east-1 (requis pour CloudFront CLOUDFRONT scope)

resource "aws_wafv2_web_acl" "app" {
  provider    = aws.us_east_1
  name        = "lamenagere-waf-${var.environnement}"
  scope       = "CLOUDFRONT"
  description = "WAF La Menagere - protection API et documents"

  default_action {
    allow {}
  }

  # 1. Règles AWS gérées — protection de base
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # 2. Protection contre les bots connus malveillants
  rule {
    name     = "AWSManagedRulesBotControlRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"

        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            inspection_level = "COMMON"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BotControl"
      sampled_requests_enabled   = true
    }
  }

  # 3. Protection contre les injections SQL
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # 4. Rate limiting custom — 1000 req/5min par IP
  rule {
    name     = "RateLimitParIP"
    priority = 40

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 1000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitIP"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "lamenagere-waf"
    sampled_requests_enabled   = true
  }
}

# Logs WAF vers S3 désactivés — le bucket WAF doit commencer par "aws-waf-logs-"
# Le monitoring se fait via les alarmes CloudWatch (waf_blocages)
