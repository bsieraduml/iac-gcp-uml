#https://www.educative.io/answers/how-to-create-a-vmvirtual-machine-on-gcp-with-terraform

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# this resource is defined to enable the Compute Engine API
resource "google_project_service" "compute_service" {
  project = var.project_id
  service = "compute.googleapis.com"
}

#this creates a custom VPC without auto created subnetworks; also removes all the default routes; ensures compute engine api is enabled first
resource "google_compute_network" "vpc_network" {
  name = "vnet-gcp-uml"
  auto_create_subnetworks = false
  delete_default_routes_on_create = true
  depends_on = [
    google_project_service.compute_service
  ]
}

#this is my private subnetwork
resource "google_compute_subnetwork" "private_network" {
  name          = "subnet-private-01-gcp-uml"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_router" "router" {
  name    = "quickstart-router"
  network = google_compute_network.vpc_network.self_link
}

resource "google_compute_router_nat" "nat" {
  name                               = "quickstart-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_route" "private_network_internet_route" {
  name             = "private-network-internet"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc_network.self_link
  next_hop_gateway = "default-internet-gateway"
  priority    = 100
}

resource "google_compute_instance" "vm_instance" {
  name         = "nginx-instance"
  machine_type = "f1-micro"

  tags = ["nginx-instance"]

  boot_disk {
    initialize_params {
      image = "centos-7-v20210420"
    }
  }


  network_interface {
    network = google_compute_network.vpc_network.self_link
    subnetwork = google_compute_subnetwork.private_network.self_link    
   
  }
}