region      = "eu-central-1"
environment = "dev"
cidr_block  = "10.19.0.0/24"

golden_amis = {
  "golden-ami-al2023-app" = {
    script_name = "install.sh"
    active      = true
    asg_name    = "frontend-2026-08"
  }
}

domain = "delivery-tst.bmw.cloud"

github_oidc_roles = {
  "terraform" = {
    role_description = "Assumed by GitHub Actions to run Terraform on the main branch"
    repositories     = ["tafy2392/minimal-health-infra-ec2-app:ref:refs/heads/main"]
    policies = [
      "arn:aws:iam::aws:policy/AdministratorAccess",
    ]
  }
  "ansible" = {
    role_description = "Assumed by GitHub Actions to run Ansible deploy on the main branch"
    repositories     = ["tafy2392/minimal-health-infra-ec2-app:ref:refs/heads/main"]
    policies = [
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
      "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
    ]
  }
}
