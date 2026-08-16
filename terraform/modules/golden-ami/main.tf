locals {
  packer_dir     = "${path.module}/packer"
  manifest_path  = "${path.module}/ami_manifest.json"
  manifest       = fileexists(local.manifest_path) ? jsondecode(file(local.manifest_path)) : null
  ami_id         = local.manifest != null ? split(":", local.manifest.builds[0].artifact_id)[1] : null
  install_script = abspath("${path.module}/scripts/${var.script_name}")
}

data "aws_iam_policy_document" "packer_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "packer" {
  name               = "${var.environment}-packer-build"
  assume_role_policy = data.aws_iam_policy_document.packer_assume_role.json
}

resource "aws_iam_role_policy_attachment" "packer_ssm" {
  role       = aws_iam_role.packer.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "packer_cloudwatch" {
  role       = aws_iam_role.packer.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "packer" {
  name = "${var.environment}-packer-build"
  role = aws_iam_role.packer.name
}

resource "null_resource" "packer_build" {
  triggers = {
    install_script_hash  = filesha256(local.install_script)
    packer_template_hash = filesha256("${local.packer_dir}/main.pkr.hcl")
    instance_profile     = aws_iam_instance_profile.packer.name
  }

  provisioner "local-exec" {
    working_dir = local.packer_dir
    command     = <<-EOT
      rm -f ../ami_manifest.json && \
      packer init . && \
      packer build \
        -var="aws_region=${var.aws_region}" \
        -var="instance_type=${var.instance_type}" \
        -var="ami_name_prefix=${var.ami_name_prefix}" \
        -var="environment=${var.environment}" \
        -var="root_volume_size_gb=${var.root_volume_size_gb}" \
        -var="vpc_id=${var.vpc_id}" \
        -var="subnet_id=${var.subnet_id}" \
        -var="iam_instance_profile=${aws_iam_instance_profile.packer.name}" \
        -var="install_script=${local.install_script}" \
        .
    EOT
  }
}
