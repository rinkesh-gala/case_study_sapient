resource "google_service_account" "sa-tf" {
  display_name = "web-vm-sa"
  account_id = "web-vm-sa"
}

resource "google_project_iam_member" "sa-iam1-tf" {
  project = var.gcp_project
  role = "roles/compute.admin"
  member = "serviceAccount:${google_service_account.sa-tf.email}"
}

resource "google_project_iam_member" "sa-iam2-tf" {
  project = var.gcp_project
  role = "roles/logging.bucketWriter"
  member = "serviceAccount:${google_service_account.sa-tf.email}"
}

resource "google_project_iam_member" "sa-iam3-tf" {
  project = var.gcp_project
  role = "roles/monitoring.admin"
  member = "serviceAccount:${google_service_account.sa-tf.email}"
}

resource "google_project_iam_member" "sa-iam4-tf" {
  project = var.gcp_project
  role = "roles/opsconfigmonitoring.resourceMetadata.writer"
  member = "serviceAccount:${google_service_account.sa-tf.email}"
}

resource "google_project_iam_member" "sa-iam5-tf" {
  project = var.gcp_project
  role = "roles/monitoring.metricWriter"
  member = "serviceAccount:${google_service_account.sa-tf.email}"
}

resource "google_compute_instance_template" "web-vm-template-tf" {
  #provider = google-beta
  name = "web-vm-template"
  machine_type = "f1-micro"
  tags = [ "allow-ssh" , "allow-http" , "allow-https" , "allow-iap"]
  #metadata_startup_script = templatefile("${path.module}/startup-script.sh", { "REPONAME" = "${google_sourcerepo_repository.bookshelf-codebase-tf.url}"})

  network_interface {
    network = var.vpc_config.id
    subnetwork = var.subnet_config.id
  }

  disk {
    auto_delete = true
    boot = true
    device_name = "web-vm-boot-disk"
    disk_name = "web-vm-boot-disk"
    mode = "READ_WRITE"
    disk_type = "pd-ssd"
    source_image = "ubuntu-os-cloud/ubuntu-2204-lts"
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

  service_account {
    email = google_service_account.sa-tf.email
    scopes = [ "cloud-platform" ]
  }

}

resource "google_compute_firewall" "fw-tf" {
  name = "web-fw-allow"
  network = var.vpc_config.id
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports = [22,80,443,8080]
  }
  source_ranges = ["35.235.240.0/20", "35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22", "169.254.169.254/32", "27.106.7.150/32"]
  target_tags = ["allow-iap", "allow-ssh"]
}

resource "google_compute_health_check" "hc-tf" {
  name = "web-health-check"
  check_interval_sec = 5
  healthy_threshold = 4
  unhealthy_threshold = 10
  timeout_sec = 2
  
  tcp_health_check {
    port = 8080
  }
}

resource "google_compute_instance_group_manager" "mig-tf" {
  name = "web-vm-mig"
  base_instance_name = "web-vm"
  zone = "us-central1-a"

  version {
  name = "web-vm-v1"
  instance_template = google_compute_instance_template.web-vm-template-tf.id
  }

  auto_healing_policies {
  health_check = google_compute_health_check.hc-tf.id
  initial_delay_sec = 400
  }

  update_policy {
  minimal_action = "REPLACE"
  type = "PROACTIVE"
  replacement_method = "SUBSTITUTE"
  max_surge_fixed = 1
  max_unavailable_fixed = 1
  }

  named_port {
  name = "http-app"
  port = 8080
  }
}

resource "google_compute_autoscaler" "autoscaler-tf" {
  name = "web-vm-autoscaler"
  target = google_compute_instance_group_manager.mig-tf.id
  autoscaling_policy {
    min_replicas = 1
    max_replicas = 2
    cooldown_period = 200
      cpu_utilization {
        #predictive_method = "OPTIMIZE_AVAILABILITY"
        target = 0.6
      }
   } 
}

resource "google_compute_global_address" "lb-ip-tf" {
  name = "https-lb-global-ip"
}

resource "google_compute_managed_ssl_certificate" "https-ssl-cert-tf" {
  depends_on = [google_compute_global_address.lb-ip-tf]
  name = "https-ssl-cert"
  managed {
    domains = ["${google_compute_global_address.lb-ip-tf.address}.nip.io"]
  }
}

resource "google_compute_ssl_policy" "https-ssl-policy-tf" {
  name = "https-ssl-policy"
  min_tls_version = "TLS_1_2"
  profile = "RESTRICTED"
}

resource "google_compute_backend_service" "https-backend-service-tf" {
  name = "https-backend-service"
  health_checks = [google_compute_health_check.hc-tf.id]
  load_balancing_scheme = "EXTERNAL"
  protocol = "HTTPS"
  port_name = "http-app"
  #custom_request_headers   = ["X-Client-Geo-Location: {client_region_subdivision}, {client_city}"]
  #locality_lb_policy = "ROUND_ROBIN"
  backend {
    group = google_compute_instance_group_manager.mig-tf.instance_group
    balancing_mode = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_url_map" "https-url-map-tf" {
  name = "external-https-lb"
  default_service = google_compute_backend_service.https-backend-service-tf.id
}

resource "google_compute_target_https_proxy" "https-target-proxy-tf" {
  name = "https-target-proxy"
  url_map = google_compute_url_map.https-url-map-tf.id
  ssl_certificates = [google_compute_managed_ssl_certificate.https-ssl-cert-tf.id]
  ssl_policy = google_compute_ssl_policy.https-ssl-policy-tf.id

}

resource "google_compute_global_forwarding_rule" "global-forwarding-rule-tf" {
  name = "global-forwarding-rule"
  target = google_compute_target_https_proxy.https-target-proxy-tf.id
  port_range = 443
  ip_address = google_compute_global_address.lb-ip-tf.id
  load_balancing_scheme = "EXTERNAL"
  ip_protocol = "TCP"
}
