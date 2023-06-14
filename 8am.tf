terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "myvpc"
  }
}

resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-1b"

  tags = {
    Name = "pubsub"
  }
}

resource "aws_subnet" "prisub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-1c"

  tags = {
    Name = "prisub"
  }
}

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "myigw"
  }
}

resource "aws_route_table" "publicrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }

  tags = {
    Name = "publicrt"
  }
}

resource "aws_route_table_association" "publicrtassociation" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.publicrt.id
}

resource "aws_eip" "myeip" {
  vpc      = true
}

resource "aws_nat_gateway" "mynat" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.pubsub.id

  tags = {
    Name = "mynat"
  }
}

resource "aws_route_table" "privatert" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.mynat.id
  }

  tags = {
    Name = "privatert"
  }
}

resource "aws_route_table_association" "privatertassociation" {
  subnet_id      = aws_subnet.prisub.id
  route_table_id = aws_route_table.privatert.id
}

resource "aws_security_group" "pubsg" {
  name        = "pubsg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "pubsg"
  }
}

resource "aws_security_group" "prisg" {
  name        = "prisg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "prisg"
  }
}

resource "aws_instance" "pub_instance" {
  ami                                             = "ami-04d1dcfb793f6fa37"
  instance_type                                   = "t2.micro"
  availability_zone                               = "us-west-1b"
  associate_public_ip_address                     = "true"
  vpc_security_group_ids                          = [aws_security_group.pubsg.id]
  subnet_id                                       = aws_subnet.pubsub.id 
  key_name                                        = "pem-nc-ch"
  
    tags = {
    Name = "Public-Server"
  }
}

resource "aws_instance" "pri_instance" {
  ami                                             = "ami-04d1dcfb793f6fa37"
  instance_type                                   = "t2.micro"
  availability_zone                               = "us-west-1c"
  associate_public_ip_address                     = "false"
  vpc_security_group_ids                          = [aws_security_group.prisg.id]
  subnet_id                                       = aws_subnet.prisub.id 
  key_name                                        = "pem-nc-ch"
  
    tags = {
    Name = "Private-Server"
  }
}