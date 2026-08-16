module "github-oidc" {
  source  = "terraform-module/github-oidc-provider/aws"
  version = "2.3.0"

  create_oidc_provider = false
  oidc_provider_arn    = var.oidc_provider_arn
  create_oidc_role     = true

  role_name        = "${var.environment}-${var.role_name}"
  role_description = var.role_description

  repositories = var.allowed_repositories

  oidc_role_attach_policies = var.policies

  tags = {
    Environment = var.environment
    Role        = var.role_name
  }
}
