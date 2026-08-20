resource "aws_vpc" "shopnow" {

  cidr_block = var.vpc_cidr

  enable_dns_hostnames = true

  tags = {
    Name = "ShopNow-VPC"
  }

}

resource "aws_subnet" "public" {

  vpc_id = aws_vpc.shopnow.id

  cidr_block = var.public_subnet

  map_public_ip_on_launch = true

  availability_zone = var.availability_zone_1

  tags = {
    Name = "Public-Subnet"
    "kubernetes.io/role/elb" = "1"
  }

}
resource "aws_subnet" "public_2" {

  vpc_id = aws_vpc.shopnow.id

  cidr_block = var.public_subnet_2

  map_public_ip_on_launch = true

  availability_zone = var.availability_zone_2

  tags = {
    Name = "Public-Subnet-B"
    "kubernetes.io/role/elb" = "1"
  }

}

resource "aws_subnet" "private" {

  vpc_id = aws_vpc.shopnow.id

  cidr_block = var.private_subnet

  availability_zone = var.availability_zone_1

  tags = {
    Name = "Private-Subnet"
    "kubernetes.io/role/internal-elb" = "1"
  }

}

resource "aws_subnet" "private_2" {

  vpc_id = aws_vpc.shopnow.id

  cidr_block = var.private_subnet_2

  availability_zone = var.availability_zone_2

  tags = {
    Name = "Private-Subnet-B"
    "kubernetes.io/role/internal-elb" = "1"
  }

}

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.shopnow.id

  tags = {
    Name = "ShopNow-IGW"
  }

}

resource "aws_route_table" "public" {

  vpc_id = aws_vpc.shopnow.id

  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.igw.id

  }

}

resource "aws_route_table_association" "public" {

  subnet_id = aws_subnet.public.id

  route_table_id = aws_route_table.public.id

}

resource "aws_route_table_association" "public_2" {

  subnet_id = aws_subnet.public_2.id

  route_table_id = aws_route_table.public.id

}

# ELASTIC IP - NAT GATEWAY 

resource "aws_eip" "nat_a" {

  domain = "vpc"

  tags = {
    Name = "ShopNow-NAT-EIP-A"
  }

}

resource "aws_eip" "nat_b" {

  domain = "vpc"

  tags = {
    Name = "ShopNow-NAT-EIP-B"
  }

}

# NAT GATEWAY A
# Public Subnet A -> NAT Gateway A

resource "aws_nat_gateway" "nat_a" {

  allocation_id = aws_eip.nat_a.id

  subnet_id = aws_subnet.public.id

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "ShopNow-NAT-Gateway-A"
  }

}

# NAT GATEWAY B -> Public Subnet B -> NAT Gateway B

resource "aws_nat_gateway" "nat_b" {

  allocation_id = aws_eip.nat_b.id

  subnet_id = aws_subnet.public_2.id

  depends_on = [
    aws_internet_gateway.igw
  ]

  tags = {
    Name = "ShopNow-NAT-Gateway-B"
  }

}

# PRIVATE ROUTE TABLE A -> # Private Subnet A -> NAT Gateway A

resource "aws_route_table" "private_a" {

  vpc_id = aws_vpc.shopnow.id

  route {

    cidr_block = "0.0.0.0/0"

    nat_gateway_id = aws_nat_gateway.nat_a.id

  }

  tags = {
    Name = "ShopNow-Private-Route-Table-A"
  }

}

# PRIVATE ROUTE TABLE B -> # Private Subnet B -> NAT Gateway B
resource "aws_route_table" "private_b" {

  vpc_id = aws_vpc.shopnow.id

  route {

    cidr_block = "0.0.0.0/0"

    nat_gateway_id = aws_nat_gateway.nat_b.id

  }

  tags = {
    Name = "ShopNow-Private-Route-Table-B"
  }

}

# PRIVATE SUBNET A ASSOCIATION
resource "aws_route_table_association" "private_a" {

  subnet_id = aws_subnet.private.id

  route_table_id = aws_route_table.private_a.id

}

# PRIVATE SUBNET B ASSOCIATION
resource "aws_route_table_association" "private_b" {

  subnet_id = aws_subnet.private_2.id

  route_table_id = aws_route_table.private_b.id

}