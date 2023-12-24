provider "aws" {
  region = "eu-west-1"
}

#variable "subnet_cidr_block" {
#  description = "subnet cidr block"
#}
#
#variable "vpc_cidr_block" {
#  description = "vpc cidr block"
#}
#
#variable "environment" {
#  description = "deployment environment"
#}
#
#variable "avail_zone" {}
#
#variable "cidr_blocks" {
#  description = "cidr blocks for vpc and subnet"
#  type = list(object({
#    cidr_block = string,
#    name = string
#  }))
#}
#
#resource "aws_vpc" "development-vpc" {
#  cidr_block = var.cidr_blocks[0].cidr_block
#  enable_dns_hostnames = true
#  tags = {
#    Name = var.cidr_blocks[0].name
#  }
#}
#
#resource "aws_subnet" "dev-subnet-1" {
#  vpc_id = aws_vpc.development-vpc.id
#  cidr_block = "10.0.10.0/24"
#  availability_zone = var.avail_zone[0]
#  tags = {
#    name = "myapp-subnet-1"
#  }
#}
#
#data "aws_vpc" "existing-vpc" {
#  default = true
#}
#
#resource "aws_subnet" "dev-subnet-2" {
#  vpc_id = data.aws_vpc.existing-vpc.id
#  cidr_block = var.cidr_blocks[1].cidr_block
##  cidr_block = "172.31.48.0/20"
#  availability_zone = var.avail_zone[1]
#  tags = {
#    Name = var.cidr_blocks[1].name
#  }
#}

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "public_key_location" {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags       = {
    Name = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id            = aws_vpc.myapp-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags              = {
    Name = "${var.env_prefix}-subnet-1"
  }
}

#resource "aws_route_table" "myapp-route-table" {
#  vpc_id = aws_vpc.myapp-vpc.id
#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = aws_internet_gateway.myapp-igw.id
#  }
#  tags = {
#    Name = "${var.env_prefix}-rtb"
#  }
#}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags   = {
    Name = "${var.env_prefix}-igw"
  }
}

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name = "${var.env_prefix}-rtb"
  }
}

resource "aws_security_group" "myapp-sg" {
  name = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port   = 8080
    protocol    = "tcp"
    to_port     = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    protocol        = "-1"
    to_port         = 0
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name = "${var.env_prefix}-sg"
  }
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
#  filter {
#    name   = "description"
#    values = ["Amazon Linux AMI 2*x86_64 ECS HVM GP2"]
#  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

#output "myapp-aws-ami" {
#  value = data.aws_ami.latest-amazon-linux-image
#}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.public_key_location)
}

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  associate_public_ip_address = true
  availability_zone = var.avail_zone

  user_data = file("user-script.sh")

  key_name = aws_key_pair.ssh-key.key_name
  tags = {
    Name = "${var.env_prefix}-server"
  }
}

#resource "aws_route_table_association" "asc-rtb-subnet" {
#  route_table_id = aws_route_table.myapp-route-table.id
#  subnet_id = aws_subnet.myapp-subnet-1.id
#}