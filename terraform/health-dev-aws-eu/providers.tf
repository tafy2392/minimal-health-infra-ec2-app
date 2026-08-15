terraform {
  required_version = "~> 1.11"

  backend "s3" {
  }

  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.60"
    }

  }
}

provider "aws" {
  region = var.region
}
