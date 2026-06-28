resource "aws_security_group" "public_sg" {

  name = "public-sg"

  vpc_id = aws_vpc.shopnow.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  // Your public Ip should given as ["120.60.20.161/32"] 
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks=["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks=["0.0.0.0/0"]
  }

  ingress {
    from_port = 3000  //frontend port
    to_port = 3000
    protocol = "tcp"
    cidr_blocks=["0.0.0.0/0"]
  }

  ingress {
    from_port = 3001   //admin dashboard port
    to_port = 3001
    protocol = "tcp"
    cidr_blocks=["0.0.0.0/0"]
  }

  egress {
    from_port=0
    to_port=0
    protocol="-1"
    cidr_blocks=["0.0.0.0/0"]
  }

}

resource "aws_instance" "frontend" {

  ami = var.ami_id

  instance_type = var.instance_type

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.public_sg.id
  ]

  associate_public_ip_address = true

  tags = {

    Name = "Frontend-Admin-Server"

  }

}