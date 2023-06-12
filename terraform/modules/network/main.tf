
resource "google_compute_network" "vpc-tf" {
    name = "migration-vpc"
    routing_mode = "GLOBAL"
    auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet-tf" {
    name = "migration-subnet"
    network = google_compute_network.vpc-tf.id
    ip_cidr_range = "10.0.0.0/23"
}

resource "google_compute_router" "router-tf" {
  name = "migration-router"
  network = google_compute_network.vpc-tf.id
  bgp {
    asn = 65000
  }
}

resource "google_compute_router_nat" "nat-tf" {
    name = "migration-nat"
    router = google_compute_router.router-tf.name
    nat_ip_allocate_option = "AUTO_ONLY"
    source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" #? check if it's a regional resource or not
}
