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

  availability_zone = "ap-south-2a"

  tags = {
    Name = "Public-Subnet"
  }

}

resource "aws_subnet" "private" {

  vpc_id = aws_vpc.shopnow.id

  cidr_block = var.private_subnet

  availability_zone = "ap-south-2a"

  tags = {
    Name = "Private-Subnet"
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