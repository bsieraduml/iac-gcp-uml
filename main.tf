# Define provider
provider "google" {
  project = "project-gcp-uml"
  region  = "us-east1"
}

# Create VPC network
resource "google_compute_network" "my_vpc" {
  name                    = "gcp-uml-vpc"
  auto_create_subnetworks = false
}

# Create public subnet
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  region        = "us-east1"
  network       = google_compute_network.my_vpc.name
  ip_cidr_range = "10.0.1.0/24"
}

# Create private subnet
resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  region        = "us-east1"
  network       = google_compute_network.my_vpc.name
  ip_cidr_range = "10.0.2.0/24"
}

# Create Managed Instance Group Instance Template for Windows Server
resource "google_compute_instance_template" "windows_instance_template" {
  name         = "windows-instance-template"
  machine_type = "n1-standard-2"
  tags         = ["allow-health-check"]

  disk {
    source_image = "projects/windows-cloud/global/images/windows-server-2022-dc-v20240214"
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.self_link
    access_config {
    }

  }

  metadata = {
    windows-startup-script-ps1 = file("startup.ps1")
  }
}

resource "google_compute_region_instance_group_manager" "default" {
  name                      = "windows-region-managed-instance-group"
  region                    = "us-east1"
  distribution_policy_zones = ["us-east1-b", "us-east1-c", "us-east1-d"]
  target_size               = 3
  base_instance_name        = "instance"
  named_port {
    name = "http"
    port = 80
  }
  version {
    instance_template = google_compute_instance_template.windows_instance_template.id
  }
  depends_on = [google_compute_instance_template.windows_instance_template]

}

resource "google_compute_firewall" "default" {
  name          = "fw-allow-health-check"
  direction     = "INGRESS"
  network       = google_compute_network.my_vpc.self_link # "global/networks/default"
  priority      = 1000
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["allow-health-check"]
  allow {
    ports    = ["80"]
    protocol = "tcp"
  }
}

resource "google_compute_global_address" "default" {
  name       = "lb-ipv4-1"
  ip_version = "IPV4"
}


resource "google_compute_health_check" "default" {
  name               = "http-basic-check"
  check_interval_sec = 5
  healthy_threshold  = 2
  http_health_check {
    port               = 80
    port_specification = "USE_FIXED_PORT"
    proxy_header       = "NONE"
    request_path       = "/"
  }
  timeout_sec         = 5
  unhealthy_threshold = 2
}

resource "google_compute_backend_service" "default" {
  name                            = "web-backend-service"
  connection_draining_timeout_sec = 0
  health_checks                   = [google_compute_health_check.default.id]
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  port_name                       = "http"
  protocol                        = "HTTP"
  session_affinity                = "NONE"
  timeout_sec                     = 30
  backend {
    group           = google_compute_region_instance_group_manager.default.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_url_map" "default" {
  name            = "web-map-http"
  default_service = google_compute_backend_service.default.id
}

resource "google_compute_target_http_proxy" "default" {
  name    = "http-lb-proxy"
  url_map = google_compute_url_map.default.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name                  = "http-content-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80-80"
  target                = google_compute_target_http_proxy.default.id
  ip_address            = google_compute_global_address.default.id
}