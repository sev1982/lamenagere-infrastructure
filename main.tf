terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # État Terraform stocké dans S3 (bootstrap manuel la première fois)
  # Créer le bucket manuellement avant le premier `terraform init`
  backend "s3" {
    bucket = "lamenagere-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "ca-central-1"
    # Optionnel : activer le verrouillage via DynamoDB
    # dynamodb_table = "lamenagere-terraform-locks"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Projet      = "lamenagere"
      Environnement = var.environnement
      Terraform   = "true"
    }
  }
}

# Provider us-east-1 requis pour CloudFront + WAF (global)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Projet        = "lamenagere"
      Environnement = var.environnement
      Terraform     = "true"
    }
  }
}
