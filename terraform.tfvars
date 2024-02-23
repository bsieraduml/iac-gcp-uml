# Application Definition 
company     = "bsierad"
app_name    = "iac-windows-uml"
app_domain  = "bensieradzki.com"
environment = "dev" # Dev, Test, Prod, etc

# GCP Settings
gcp_project = "project-gcp-uml"
gcp_region  = "us-east1"
gcp_zone    = "us-east1-b"
#gcp_auth_file = "../auth/kopicloud-medium.json"

# GCP Netwok
network-subnet-cidr = "10.10.15.0/24"

# Windows VM
windows_instance_type = "n2-standard-2"