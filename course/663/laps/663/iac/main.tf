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
  zone   = var.zone
}

resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "hello_repo" {
  depends_on    = [google_project_service.apis]
  location      = var.region
  repository_id = "hello-repo"
  format        = "DOCKER"
  description   = "Docker repository for hello app"
}

resource "google_container_cluster" "hello_cluster" {
  depends_on = [google_project_service.apis]
  name       = var.cluster_name
  location   = var.zone

  initial_node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  deletion_protection = false
}
