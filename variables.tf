# variable "project" {}

# //ben todo
# //this may go away when I go to Terraform Cloud; ditto with creds.json
# # variable "credentials_file" {}
variable "project_id" {
  default = "project-gcp-uml"
}

variable "region" {
  default = "us-east1"
}

variable "zone" {
  default = "us-east1-b"
}