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
    "run.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

# ── Source bucket ───────────────────────────────────────────
resource "google_storage_bucket" "source" {
  name                        = "${var.project_id}-gcfunction-source"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

data "archive_file" "source_zip" {
  type        = "zip"
  source_dir  = "${path.module}/source"
  output_path = "${path.module}/function-source.zip"
}

resource "google_storage_bucket_object" "source" {
  name   = "function-source-${data.archive_file.source_zip.output_md5}.zip"
  bucket = google_storage_bucket.source.name
  source = data.archive_file.source_zip.output_path
}

# ── Cloud Run Function (2nd gen) ────────────────────────────
resource "google_cloudfunctions2_function" "gcfunction" {
  name     = "gcfunction"
  location = var.region

  depends_on = [google_project_service.apis]

  build_config {
    runtime     = "nodejs20"
    entry_point = "helloHttp"
    source {
      storage_source {
        bucket = google_storage_bucket.source.name
        object = google_storage_bucket_object.source.name
      }
    }
  }

  service_config {
    max_instance_count = 5
    available_memory   = var.memory
    timeout_seconds    = 60
  }
}

# ── Allow public access ─────────────────────────────────────
resource "google_cloud_run_service_iam_member" "allow_public" {
  location = google_cloudfunctions2_function.gcfunction.location
  service  = google_cloudfunctions2_function.gcfunction.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
