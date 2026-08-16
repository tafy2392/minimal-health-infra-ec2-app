terraform {
  required_version = "~> 1.11"
}

module "backend" {
  source                       = "squareops/tfstate/aws"
  version                      = "1.1.1"
  logging                      = true
  bucket_name                  = "dev-health-aws-tfstate-bucket" #unique global s3 bucket name
  environment                  = "dev"
  force_destroy                = true
  versioning_enabled           = true
  cloudwatch_logging_enabled   = true
  log_retention_in_days        = 90
  log_bucket_lifecycle_enabled = true
  s3_ia_retention_in_days      = 90
  s3_galcier_retention_in_days = 180
}
