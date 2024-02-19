

provider "google" {
  //credentials = file("creds.json")
  project     = "project-gcp-uml"
  region      = var.region
  zone        = "us-east1-a"
}

resource "google_compute_network" "vpc_network" {
  name = "vnet-gcp-uml"
}