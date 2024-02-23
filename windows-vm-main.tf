###########################
## GCP Windows VM - Main ##
###########################

locals {
    virtual_machines = {
        "vm1" = {zone = "us-east1-b"},
        "vm2" = {zone = "us-east1-c"},
        "vm2" = {zone = "us-east1-d"}
    }
}

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
EOF
}

# Create VM
resource "google_compute_instance" "vm_instance_public" {
for_each = local.virtual_machines
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