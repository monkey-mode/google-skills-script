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

resource "google_project_service" "storage" {
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_storage_bucket" "api_demo" {
  depends_on                  = [google_project_service.storage]
  name                        = "${data.google_project.current.project_id}-api-demo"
  location                    = var.region
  uniform_bucket_level_access = false
  force_destroy               = true
}

data "google_project" "current" {}
