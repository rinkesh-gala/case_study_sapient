terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~>4.68.0"
    }
  }
  backend "gcs" {
    bucket  = "flowing-coil-348605-tf-state"
    prefix  = "terraform/state"
  }
}

module "web_network" {
  source = "./modules/network"
}

module "web_appvm" {
  source = "./modules/appvm"
  depends_on = [module.web_network]
  vpc_config = module.web_network.vpc-tf-out
}

/*
module "bookshelf_vm_template" {
  source = "./modules/apptemplate"
  depends_on = [module.bookshelf_network]
  bookshelf_vpc_config = module.bookshelf_network.bookshelf-vpc-tf-out
  bookshelf_subnet_config = module.bookshelf_network.bookshelf-app-subnet-tf-out
}*/
