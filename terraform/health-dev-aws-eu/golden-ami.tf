module "golden_ami" {
  source      = "../modules/golden-ami"
  environment = var.environment
  aws_region  = var.region
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.vpc.public_subnet_ids[0]
}
