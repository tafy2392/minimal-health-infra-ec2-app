data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = {
    Environment = var.environment
  }
}

module "github_oidc" {
  source = "../modules/github-oidc"

  for_each = var.github_oidc_roles

  environment       = var.environment
  role_name         = each.key
  role_description  = each.value.role_description
  oidc_provider_arn = aws_iam_openid_connect_provider.github.arn

  allowed_repositories = each.value.repositories
  policies             = each.value.policies
}
