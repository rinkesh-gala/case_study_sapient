provider "google" {
  project = var.gcp_project
  region = var.gcp_region
  zone = var.gcp_zone
  #credentials = file(account.json)
}

/*provider "google-beta" {
  project = var.gcp_project
  region = var.gcp_region
  zone = var.gcp_zone
}*/