output "vpc-tf-out" {
  value = google_compute_network.vpc-tf
}

output "subnet-tf-out" {
  value = google_compute_subnetwork.subnet-tf
}