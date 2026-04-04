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
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "pubsub.googleapis.com",
    "eventarc.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "serverless_repo" {
  depends_on    = [google_project_service.apis]
  location      = var.region
  repository_id = "serverless-repo"
  format        = "DOCKER"
}

resource "google_pubsub_topic" "hello_topic" {
  depends_on = [google_project_service.apis]
  name       = "hello-topic"
}

resource "google_service_account" "pubsub_invoker" {
  account_id   = "cloud-run-pubsub-invoker"
  display_name = "Cloud Run Pub/Sub Invoker"
}
