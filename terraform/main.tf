terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~>4.68.0"
    }
  }
  backend "gcs" {
    bucket  = "project-1-2-3-4-385715-tf-state"
    prefix  = "terraform/state"
  }
}

resource "google_project_service" "project1" {
  project = var.gcp_project
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "project2" {
  project = var.gcp_project
  service = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "project3" {
  project = var.gcp_project
  service = "iap.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "project4" {
  project = var.gcp_project
  service = "iap.googleapis.com"
  disable_on_destroy = false
}

module "web_network" {
  source = "./modules/network"
  gcp_project = var.gcp_project
  gcp_region = var.gcp_region
  gcp_zone = var.gcp_zone
}

module "web_appvm" {
  source = "./modules/appvm"
  depends_on = [module.web_network]
  vpc_config = module.web_network.vpc-tf-out
  subnet_config = module.web_network.subnet-tf-out
  gcp_project = var.gcp_project
  gcp_region = var.gcp_region
  gcp_zone = var.gcp_zone
  whitelist_ip = var.whitelist_ip
}

/*
module "bookshelf_vm_template" {
  source = "./modules/apptemplate"
  depends_on = [module.bookshelf_network]
  bookshelf_vpc_config = module.bookshelf_network.bookshelf-vpc-tf-out
  bookshelf_subnet_config = module.bookshelf_network.bookshelf-app-subnet-tf-out
}*/
