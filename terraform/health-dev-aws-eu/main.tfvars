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
