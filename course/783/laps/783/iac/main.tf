terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  region = var.region
}

resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

resource "google_container_cluster" "autopilot" {
  depends_on       = [google_project_service.apis]
  name             = var.cluster_name
  location         = var.region
  enable_autopilot = true
  deletion_protection = false
}
