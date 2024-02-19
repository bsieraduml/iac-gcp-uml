terraform {

  cloud {
    organization = "bsieraduml"

    workspaces {
      name = "uml-gcp-tfc-workspace"
    }
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.51.0"
    }
  }
}