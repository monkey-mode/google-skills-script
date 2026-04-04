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

# ── Enable required APIs ────────────────────────────────────
resource "google_project_service" "apis" {
  for_each = toset([
    "aiplatform.googleapis.com",
    "storage.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}
