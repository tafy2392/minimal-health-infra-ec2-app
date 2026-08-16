module "golden_ami" {
  depends_on = [module.vpc]

  for_each = var.golden_amis

  source         = "../modules/golden-ami"
  environment    = var.environment
  aws_region     = var.region
  vpc_id         = module.vpc.vpc_id
  subnet_id      = module.vpc.public_subnet_ids[0]
  ami_name_prefix = each.key
  script_name     = each.value.script_name
}
