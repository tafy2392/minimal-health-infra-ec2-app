data "aws_caller_identity" "current" {}

module "ansible_ssm_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 5.0"

  bucket        = "${var.environment}-ansible-ssm-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  versioning = {
    enabled = false
  }

  # Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Environment = var.environment
    Purpose     = "ansible-ssm-transfers"
  }
}

data "aws_iam_policy_document" "ansible_ssm_s3" {
  statement {
    sid    = "BucketLevel"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [module.ansible_ssm_bucket.s3_bucket_arn]
  }

  statement {
    sid    = "ObjectLevel"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["${module.ansible_ssm_bucket.s3_bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "ansible_ssm_s3" {
  name        = "${var.environment}-ansible-ssm-s3"
  description = "Allows the Ansible SSM connection plugin to transfer files via the SSM S3 bucket"
  policy      = data.aws_iam_policy_document.ansible_ssm_s3.json
}

resource "aws_iam_role_policy_attachment" "ansible_ssm_s3" {
  role       = "${var.environment}-ansible"
  policy_arn = aws_iam_policy.ansible_ssm_s3.arn

  depends_on = [module.github_oidc]
}
