variable "aws_region" {
  description = "Région AWS principale"
  type        = string
  default     = "ca-central-1"
}

variable "environnement" {
  description = "prod | staging"
  type        = string
  default     = "prod"
}

variable "domaine" {
  description = "Domaine principal (ex: lamenagere.ca)"
  type        = string
}

variable "supabase_url" {
  description = "URL du projet Supabase"
  type        = string
  sensitive   = true
}

variable "supabase_service_role_key" {
  description = "Clé service_role Supabase (Lambda)"
  type        = string
  sensitive   = true
}

variable "resend_api_key" {
  description = "Clé API Resend (Lambda rappels)"
  type        = string
  sensitive   = true
}

variable "app_url" {
  description = "URL publique de l'application Next.js"
  type        = string
  default     = "https://lamenagere-three.vercel.app"
}

variable "alerte_email" {
  description = "Email pour les alarmes CloudWatch"
  type        = string
}
