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
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "my_sa" {
  depends_on   = [google_project_service.apis]
  account_id   = "my-sa-123"
  display_name = "My Service Account"
  description  = "Lab service account for IAM exercises"
}

resource "google_project_iam_member" "editor" {
  project = data.google_project.current.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.my_sa.email}"
}

resource "google_project_iam_custom_role" "compute_viewer" {
  role_id     = "customComputeViewer"
  title       = "Custom Compute Viewer"
  description = "Read-only access to Compute Engine instances"
  permissions = ["compute.instances.get", "compute.instances.list"]
}

resource "google_project_iam_member" "custom_role_binding" {
  project = data.google_project.current.project_id
  role    = google_project_iam_custom_role.compute_viewer.id
  member  = "serviceAccount:${google_service_account.my_sa.email}"
}

resource "google_compute_instance" "sa_vm" {
  depends_on   = [google_project_service.apis]
  name         = "sa-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  service_account {
    email  = google_service_account.my_sa.email
    scopes = ["cloud-platform"]
  }
}

data "google_project" "current" {}
