resource "google_service_account" "a-sa-tf" {
  display_name = "ansible-vm-sa"
  account_id = "ansible-vm-sa"
}

resource "google_project_iam_member" "a-sa-iam1-tf" {
  project = var.gcp_project
  role = "roles/compute.admin"
  member = "serviceAccount:${google_service_account.a-sa-tf.email}"
}

resource "google_project_iam_member" "a-sa-iam2-tf" {
  project = var.gcp_project
  role = "roles/logging.bucketWriter"
  member = "serviceAccount:${google_service_account.a-sa-tf.email}"
}

resource "google_project_iam_member" "a-sa-iam3-tf" {
  project = var.gcp_project
  role = "roles/monitoring.admin"
  member = "serviceAccount:${google_service_account.a-sa-tf.email}"
}

resource "google_project_iam_member" "a-sa-iam4-tf" {
  project = var.gcp_project
  role = "roles/opsconfigmonitoring.resourceMetadata.writer"
  member = "serviceAccount:${google_service_account.a-sa-tf.email}"
}

resource "google_project_iam_member" "a-sa-iam5-tf" {
  project = var.gcp_project
  role = "roles/monitoring.metricWriter"
  member = "serviceAccount:${google_service_account.a-sa-tf.email}"
}

resource "google_compute_instance" "ansible-vm-tf" {
  name = "ansible-master"
  machine_type = "n1-standard-2"
  tags = [ "allow-iap", "allow-ssh" ]

  network_interface {
    network = var.vpc_config.id
    subnetwork = var.subnet_config.id
  }
  
   boot_disk {
    #device_name = "ansible-vm-boot-disk"
     initialize_params {
      type = "pd-ssd"
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
     }
  }

   service_account {
    email = google_service_account.a-sa-tf.email
    scopes = [ "cloud-platform" ]
  }

  scheduling {
    preemptible = true
    automatic_restart = false
    provisioning_model = "SPOT"  
  }

   shielded_instance_config {
    enable_secure_boot =  true
    enable_vtpm = true
    enable_integrity_monitoring = true
  }
}