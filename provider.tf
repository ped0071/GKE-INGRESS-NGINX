terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.73.0"
    }
  }
}

provider "google" {
  region = var.region
  project = var.project
  credentials = file("credentials.json")
}
