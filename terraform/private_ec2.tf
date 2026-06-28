resource "aws_security_group" "private_sg" {

  name = "private-sg"

  vpc_id = aws_vpc.shopnow.id

  ingress {

    from_port = 5000    //backend port

    to_port = 5000

    protocol = "tcp"

    security_groups = [
      aws_security_group.public_sg.id
    ]

  }

  ingress {

    from_port = 27017

    to_port = 27017

    protocol = "tcp"

    security_groups = [
      aws_security_group.public_sg.id
    ]

  }

  ingress {

    from_port = 22

    to_port = 22

    protocol = "tcp"

    security_groups = [
      aws_security_group.public_sg.id
    ]

  }

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

}



resource "aws_instance" "backend" {

  ami = var.ami_id

  instance_type = var.instance_type

  subnet_id = aws_subnet.private.id

  vpc_security_group_ids = [
    aws_security_group.private_sg.id
  ]

  associate_public_ip_address = false

  tags = {

    Name = "Backend-MongoDB-Server"

  }

}