# ── Lambda — Rappels quotidiens (missions du lendemain) ───────────────────────

# Archive du code Lambda (créée par `npm run build:lambda`)
data "archive_file" "rappel" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/rappel"
  output_path = "${path.module}/../lambda/rappel.zip"
}

# Rôle IAM pour la Lambda
resource "aws_iam_role" "lambda_rappel" {
  name = "lamenagere-lambda-rappel-${var.environnement}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_rappel.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Politique SES pour la Lambda
resource "aws_iam_role_policy" "lambda_ses" {
  name = "lambda-ses-send"
  role = aws_iam_role.lambda_rappel.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ses:SendEmail", "ses:SendRawEmail"]
      Resource = "*"
    }]
  })
}

# Groupe de logs CloudWatch
resource "aws_cloudwatch_log_group" "lambda_rappel" {
  name              = "/aws/lambda/lamenagere-rappel-${var.environnement}"
  retention_in_days = 30
}

# Fonction Lambda
resource "aws_lambda_function" "rappel" {
  function_name = "lamenagere-rappel-${var.environnement}"
  role          = aws_iam_role.lambda_rappel.arn
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  timeout       = 60
  memory_size   = 256

  filename         = data.archive_file.rappel.output_path
  source_code_hash = data.archive_file.rappel.output_base64sha256

  environment {
    variables = {
      SUPABASE_URL              = var.supabase_url
      SUPABASE_SERVICE_ROLE_KEY = var.supabase_service_role_key
      RESEND_API_KEY            = var.resend_api_key
      APP_URL                   = var.app_url
      AWS_SES_REGION            = "us-east-1"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_rappel,
    aws_iam_role_policy_attachment.lambda_logs,
  ]
}

# EventBridge — déclenche la Lambda chaque jour à 09h00 EST (14h00 UTC)
resource "aws_cloudwatch_event_rule" "rappel_quotidien" {
  name                = "lamenagere-rappel-quotidien-${var.environnement}"
  description         = "Rappels emails missions du lendemain — 9h00 EST"
  schedule_expression = "cron(0 14 * * ? *)"
}

resource "aws_cloudwatch_event_target" "rappel" {
  rule      = aws_cloudwatch_event_rule.rappel_quotidien.name
  target_id = "lambda-rappel"
  arn       = aws_lambda_function.rappel.arn
}

resource "aws_lambda_permission" "eventbridge_rappel" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rappel.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rappel_quotidien.arn
}

# ── Lambda — Upload documents vers S3 (presigned URL) ────────────────────────
# Les presigned URLs sont générées directement depuis l'API Next.js (AWS SDK)
# Pas besoin d'une Lambda séparée pour ça.
