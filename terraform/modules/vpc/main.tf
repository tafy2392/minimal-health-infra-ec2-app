locals {

  new_bits = 26 - split("/", var.cidr_block)[1]

  # Calculate total number of possible subnets (2^new_bits, e.g., 2^2 = 4)
  total_subnets = pow(2, local.new_bits)

  # Generate all subnet CIDRs dynamically using a loop
  all_cidrs = [
    for i in range(local.total_subnets) : cidrsubnet(var.cidr_block, local.new_bits, i)
  ]

  # Split the list cleanly in half using slice()
  # First 2 become public, last 2 become private
  half_count    = local.total_subnets / 2
  public_cidrs  = slice(local.all_cidrs, 0, local.half_count)
  private_cidrs = slice(local.all_cidrs, local.half_count, local.total_subnets)
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block

  tags = {
    Name = var.environment
  }
}

# Dynamically provision public subnets from the first half
resource "aws_subnet" "public" {
  for_each = { for idx, cidr in local.public_cidrs : idx => cidr }

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  map_public_ip_on_launch = false

  tags = {
    Name = "public-${each.key}"
  }
}

# Dynamically provision private subnets from the second half
resource "aws_subnet" "private" {
  for_each = { for idx, cidr in local.private_cidrs : idx => cidr }

  vpc_id     = aws_vpc.main.id
  cidr_block = each.value

  tags = {
    Name = "private-${each.key}"
  }
}
