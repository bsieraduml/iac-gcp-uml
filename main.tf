

provider "google" {
  //credentials = file("creds.json")
  project = "project-gcp-uml"
  region  = var.region
  zone    = "us-east1-a"
}

# resource "google_compute_network" "vpc_network" {
#   name = "vnet-gcp-uml"
# }

# resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges" {
#   name          = "subnet-private-01-gcp-uml"
#   ip_cidr_range = "10.0.1.0/24"
#   region        = var.region
#   network       = google_compute_network.vpc_network.id
# }