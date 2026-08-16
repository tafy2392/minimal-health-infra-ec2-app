# minimal-health-infra-ec2-app

Terraform infrastructure for a minimal health application running on EC2.

Provisions a VPC and builds a hardened Amazon Linux 2023 golden AMI via Packer with Git, Python 3.13, Docker CE, and Docker Compose pre-installed.

## Requirements

- Terraform ~> 1.11
- Packer ~> 1.15
- [AWS Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
- AWS credentials with EC2, IAM, and SSM permissions

## Setup

```bash
brew install terraform
brew install packer
brew install --cask session-manager-plugin
```

## Structure

```
terraform/
  health-dev-aws-eu/   # dev environment
  modules/
    vpc/               # VPC, subnets, routing
    golden-ami/        # Packer-based AMI build
```
