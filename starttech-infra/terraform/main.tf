provider "aws" {
  region = var.aws_region
}


module "networking" {
  source = "./modules/networking"
}

module "storage" {
  source = "./modules/storage"
}

module "compute" {
  source          = "./modules/compute"
  vpc_id          = module.networking.vpc_id
  public_subnets  = module.networking.public_subnets
}

module "monitoring" {
  source = "./modules/monitoring"
}
