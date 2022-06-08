aws_account   = "898092969108" //ID 12 digits AWS account
environment   = "TERRAFORM-LAB"
aws_region    = "ap-southeast-1"
vpc_cidr      = "10.0.0.0/16"

public_subnets_cidr  = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnets_cidr = ["10.0.2.0/24", "10.0.3.0/24"]
db_subnets_cidr      = ["10.0.4.0/24", "10.0.5.0/24"]