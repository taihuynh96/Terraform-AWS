variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_account" {
  type = string
}

///////Bien VPC//////////
variable "vpc_cidr" {
  description = "CIDR block of the vpc"
}

variable "public_subnets_cidr" {
  type        = list
  description = "CIDR block for Public Subnet"
}

variable "private_subnets_cidr" {
  type        = list
  description = "CIDR block for Private Subnet"
}

variable "db_subnets_cidr" {
  type        = list
  description = "CIDR block for db Subnet"
}
