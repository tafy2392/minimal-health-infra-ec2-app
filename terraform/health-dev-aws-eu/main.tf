data "aws_ssm_parameter" "github_ssh_key" {
  name            = var.github_ssh_key_ssm_param
  with_decryption = true
}

module "aws-lb-sg" {
  source = "../modules/aws-lb-asg"

  depends_on     = [module.vpc, module.golden_amis]
  golden_ami_ids = { for key, ami in module.golden_amis : key => ami.ami_id }
  active_ami     = [for key, ami in var.golden_amis : key if ami.active][0]
  amis           = var.golden_amis
  # we will use public subnet ids since we dont have an IGW for private subnets
  subnet_ids  = module.vpc.public_subnet_ids
  environment = var.environment
  vpc_id      = module.vpc.vpc_id

  # we dont manage the domain so we are importing the certificate already in aws cert manager
  https_listener_certificate_arn = data.aws_acm_certificate.lb_certificate_frontend.arn

  repo_url       = var.repo_url
  github_ssh_key = data.aws_ssm_parameter.github_ssh_key.value
}
