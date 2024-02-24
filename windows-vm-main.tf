###########################
## GCP Windows VM - Main ##
###########################

# locals {
#     virtual_machines = {
#         "vm1" = {zone = "us-east1-b"},
#         "vm2" = {zone = "us-east1-c"},
#         "vm3" = {zone = "us-east1-d"}
#     }
# }

# Terraform plugin for creating random ids
resource "random_id" "instance_id" {
  byte_length = 4
}

# Bootstrapping Script
data "template_file" "windows-metadata" {
  template = <<EOF
# Install IIS
Install-WindowsFeature -name Web-Server -IncludeManagementTools;
Install-WindowsFeature Web-Asp-Net45;
Remove-Item C:\inetpub\wwwroot\*.*
hostname | Out-File c:\inetpub\wwwroot\index.html
EOF
}

# Create VM
resource "google_compute_instance" "vm_instance_public" {
for_each = var.myvms
  name         = "${lower(each.key)}-${lower(var.company)}-${lower(var.app_name)}-${var.environment}-vm${random_id.instance_id.hex}"
  machine_type = var.windows_instance_type
  zone         = each.value.zone
  hostname     = "${lower(each.key)}-${var.app_name}-vm${random_id.instance_id.hex}.${var.app_domain}"
  tags         = ["rdp", "http"]

  boot_disk {
    initialize_params {
      image = var.windows_2022_sku
    }
  }

  metadata = {
    sysprep-specialize-script-ps1 = data.template_file.windows-metadata.rendered
  }

  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.network_subnet.name
    access_config {}
  }
} 

resource "google_compute_http_health_check" "health_check_lb" {
  check_interval_sec  = 5
  healthy_threshold   = 2
  name                = "health-check-lb"
  port                = 80
  project             = "project-gcp-uml"
  request_path        = "/"
  timeout_sec         = 5
  unhealthy_threshold = 2
}
#target = "https://www.googleapis.com/compute/beta/projects/project-gcp-uml/regions/us-east1/targetPools/lb-test"
resource "google_compute_forwarding_rule" "frontend_lb" {
 # ip_address            = "34.23.191.115"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  name                  = "frontend-lb"
  network_tier          = "PREMIUM"
  port_range            = "80-80"
  project               = "project-gcp-uml"
  region                = "us-east1"
  target                = google_compute_target_pool.lb_test.id
}
#health_checks = ["https://www.googleapis.com/compute/beta/projects/project-gcp-uml/global/httpHealthChecks/health-check-lb"]
#instances = ["us-east1-b/vm1-bsierad-iac-windows-uml-dev-vm239dea64", "us-east1-c/vm2-bsierad-iac-windows-uml-dev-vm239dea64", "us-east1-d/vm3-bsierad-iac-windows-uml-dev-vm239dea64"]
resource "google_compute_target_pool" "lb_test" {
  for_each = var.myvms
  health_checks    = [google_compute_http_health_check.health_check_lb.name]
  instances        = ["${each.value.zone}/${lower(each.key)}-${var.app_name}-vm${random_id.instance_id.hex}.${var.app_domain}"]
  name             = "lb-test"
  project          = "project-gcp-uml"
  region           = "us-east1"
  session_affinity = "NONE"
}