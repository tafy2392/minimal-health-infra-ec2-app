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

resource "aws_route_table_association" "private" {
  for_each = { for idx, cidr in local.private_cidrs : idx => cidr }

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table_association" "public" {
  for_each = { for idx, cidr in local.public_cidrs : idx => cidr }
   
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}
