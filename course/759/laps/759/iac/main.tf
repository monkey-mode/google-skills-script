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
    "securitycenter.googleapis.com",
    "cloudasset.googleapis.com",
    "compute.googleapis.com",
    "bigquery.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

resource "google_bigquery_dataset" "scc_findings" {
  depends_on  = [google_project_service.apis]
  dataset_id  = "scc_findings"
  location    = "US"
  description = "SCC findings export"
}
