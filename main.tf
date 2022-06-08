terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.27"
    }
  } 
}

provider "aws" {
  region = "ap-southeast-1"
}
locals {
  ami = "ami-04d9e855d716f9c99"
  instance_type = "t2.micro"
  name = "demo-lab"
}

resource "aws_instance" "myapp" {
  ami = local.ami
  instance_type = local.instance_type
  tags = {
  Name = local.name
  }
}


