provider "aws" {
  region = "eu-west-1"
  access_key = "AKIAQAAMHAMVZ2FKPKZY"
  secret_key = "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"
}

variable "subnet_cidr_block" {
  description = "subnet cidr block"
}

variable "vpc_cidr_block" {
  description = "vpc cidr block"
}

variable "environment" {
  description = "deployment environment"
}

variable "cidr_blocks" {
  description = "cidr blocks for vpc and subnet"
  type = list(object({
    cidr_block = string,
    name = string
  }))
}

resource "aws_vpc" "development-vpc" {
  cidr_block = var.cidr_blocks[0].cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = var.cidr_blocks[0].name
  }
}

resource "aws_subnet" "dev-subnet-1" {
  vpc_id = aws_vpc.development-vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "eu-west-1a"
  tags = {
    name = "dev-subnet-1"
  }
}

data "aws_vpc" "existing-vpc" {
  default = true
}

resource "aws_subnet" "dev-subnet-2" {
  vpc_id = data.aws_vpc.existing-vpc.id
  cidr_block = var.cidr_blocks[1].cidr_block
#  cidr_block = "172.31.48.0/20"
  availability_zone = "eu-west-1b"
  tags = {
    Name = var.cidr_blocks[1].name
  }
}