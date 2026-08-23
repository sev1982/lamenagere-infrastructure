# La Ménagère — AWS Infrastructure (Terraform)

Infrastructure-as-Code module powering **La Ménagère**, a multilingual (FR/EN/ES/AR) SaaS marketplace for home services, targeting 30+ countries. This repository contains only the AWS infrastructure layer — application source code and business logic are maintained in a separate private repository.

## Full Target Architecture

<img width="1093" height="1050" alt="aws_architecture" src="https://github.com/user-attachments/assets/e7e33347-6ccd-42dc-98bc-91452916516f" />
                
              
                
## Technologies

- **Terraform** — Infrastructure as Code, modular `.tf` configuration
- **Amazon S3** — Storage for static assets and user-uploaded documents
- **Amazon CloudFront** — CDN for global content delivery and edge caching
- **AWS Lambda** — Serverless compute; each backend API route runs as an independent, on-demand function with no persistent server
- **AWS WAF** — Web Application Firewall protecting public-facing endpoints from common exploits (SQL injection, XSS, rate-based abuse)
- **Amazon CloudWatch** — Centralized monitoring, logging, and alerting across all services
- **Amazon SES** — Transactional email delivery (notifications, confirmations)

## Deployment

```bash
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

Copy `terraform.tfvars.example` to `terraform.tfvars` and populate it with your own environment-specific values before running. Real credentials and state files are excluded from version control (see `.gitignore`).

## Security Considerations

- **WAF rules**: Configured to filter malicious request patterns (SQL injection, cross-site scripting, known bad IP ranges) before traffic reaches application endpoints — the most technically demanding part of this build, requiring careful rule tuning to avoid false positives on legitimate marketplace traffic
- **Least-privilege IAM**: Lambda execution roles are scoped to only the specific S3 actions and resources they require, not broad account-level access
- **Encryption**: S3 bucket enforces encryption at rest; CloudFront enforces HTTPS-only delivery
- **No hardcoded secrets**: All sensitive values (API keys, bucket names, ARNs) are managed through Terraform variables, never committed to version control
- **State file isolation**: `.tfstate` files are excluded from this repository to avoid exposing resource identifiers and configuration details

## Challenges

Tuning the WAF ruleset was the most demanding part of this build. Overly aggressive rules generated false positives that blocked legitimate marketplace traffic (e.g., search queries with special characters), while overly permissive rules left common attack vectors unmitigated. This required iterative testing against real traffic patterns to strike the right balance between security and usability.

## Lessons Learned

- Serverless architecture (Lambda per API route) significantly simplifies scaling compared to maintaining persistent servers, but requires careful attention to cold-start behavior and IAM permission scoping per function
- WAF is not "set and forget" ; it needs to be tuned against actual application traffic, not just generic rule templates
- Separating infrastructure code from application code (this repository vs. the private app repository) makes the security posture of the infrastructure layer easier to audit independently

## About This Project

La Ménagère is a solo-built, ~72% complete multilingual SaaS marketplace connecting households with home-service providers across 30+ countries. Built with Next.js, Supabase, Stripe, and deployed via Vercel, with this AWS layer handling storage, content delivery, and serverless compute.
