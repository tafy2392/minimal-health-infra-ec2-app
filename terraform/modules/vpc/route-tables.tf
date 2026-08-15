resource "aws_route_table" "private" {
  for_each = { for idx, cidr in local.private_cidrs : idx => cidr }

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-${each.key}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-public"
  }
}
