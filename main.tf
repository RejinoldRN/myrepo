terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "CTS-VPC"
  }
}

resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone="ap-south-1a"
  
  tags = {
    Name = "PUBLIC SUBNET"
  }
}

resource "aws_subnet" "prisub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone="ap-south-1b"
  
  tags = {
    Name = "PRIVATE SUBNET"
  }
}

resource "aws_internet_gateway" "tigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "INTERNET GATEWAY"
  }
}

resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tigw.id
  }

  tags = {
    Name = "PUBLIC ROUTE TABLE"
  }
}

resource "aws_route_table_association" "pubsubassociation" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pubrt.id
}

resource "aws_eip" "teip" {
    vpc      = true
}

resource "aws_nat_gateway" "tnat" {
  allocation_id = aws_eip.teip.id
  subnet_id     = aws_subnet.pubsub.id

  tags = {
    Name = "NAT-GATEWAY"
  }
}


resource "aws_route_table" "prirt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tigw.id
  }

  tags = {
    Name = "PRIVATE ROUTE TABLE"
  }
}

resource "aws_route_table_association" "prisubassociation" {
  subnet_id      = aws_subnet.prisub.id
  route_table_id = aws_route_table.prirt.id
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
  }

  tags = {
    Name = "PUBLIC SECURITY GROUP"
  }
}

resource "aws_security_group" "prisg" {
  name        = "prisg"
  description = "Allow TLS inbound traffic from Publis Subnet"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["10.0.1.0/24"]    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]    
  }

  tags = {
    Name = "PRIVATE SECURITY GROUP"
  }
}

resource "aws_instance" "pub_instance" {
  ami                                                     = "ami-052cef05d01020f1d"
  instance_type                                   = "t2.micro"
  availability_zone                              = "ap-south-1a"
  associate_public_ip_address         = "true"
  vpc_security_group_ids                 = [aws_security_group.pubsg.id]
  subnet_id                                          = aws_subnet.pubsub.id 
  key_name                                         = "GIT-KEY"
  
    tags = {
    Name = "HDFCBANK WEBSERVER"
  }
}

resource "aws_instance" "pri_instance" {
  ami                                                     = "ami-052cef05d01020f1d"
  instance_type                                   = "t2.micro"
  availability_zone                              = "ap-south-1b"
  associate_public_ip_address         = "false"
  vpc_security_group_ids                 = [aws_security_group.prisg.id]
  subnet_id                                          = aws_subnet.prisub.id 
  key_name                                         = "GIT-KEY"
  
    tags = {
    Name = "HDFCBANK APPSERVER"
  }
}

