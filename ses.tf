# ── AWS SES — Emails transactionnels avec domaine vérifié ─────────────────────
# SES doit être en us-east-1 ou ca-central-1
# Utiliser us-east-1 pour la disponibilité maximale

resource "aws_sesv2_email_identity" "domaine" {
  provider       = aws.us_east_1
  email_identity = var.alerte_email
  # Vérification par email individuel — remplacer par var.domaine quand lamenagere.ca est enregistré
}

# Configuration set pour le suivi des envois
resource "aws_sesv2_configuration_set" "principal" {
  provider               = aws.us_east_1
  configuration_set_name = "lamenagere-${var.environnement}"

  sending_options   { sending_enabled = true }
  reputation_options { reputation_metrics_enabled = true }

  suppression_options {
    suppressed_reasons = ["BOUNCE", "COMPLAINT"]
  }
}

# Logs SES → CloudWatch
resource "aws_sesv2_configuration_set_event_destination" "cloudwatch" {
  provider               = aws.us_east_1
  configuration_set_name = aws_sesv2_configuration_set.principal.configuration_set_name
  event_destination_name = "cloudwatch-logs"

  event_destination {
    enabled = true
    matching_event_types = [
      "SEND", "DELIVERY", "BOUNCE", "COMPLAINT", "REJECT"
    ]
    cloud_watch_destination {
      dimension_configuration {
        default_dimension_value = "none"
        dimension_name          = "MessageTag"
        dimension_value_source  = "MESSAGE_TAG"
      }
    }
  }
}
