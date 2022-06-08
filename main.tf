locals {
  production_availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
}
module "vpc" {
  source              = "./modules/vpc"
  region               = var.aws_region
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnets_cidr  = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
  db_subnets_cidr      = var.db_subnets_cidr
  availability_zones   = local.production_availability_zones
}