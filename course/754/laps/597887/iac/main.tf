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

# ── Enable required APIs ────────────────────────────────────
resource "google_project_service" "compute" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# ── Firewall ────────────────────────────────────────────────
resource "google_compute_firewall" "allow_http" {
  depends_on = [google_project_service.compute]
  name        = "allow-http"
  network     = "default"
  description = "Allow HTTP traffic on port 80"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# ── VM: gcelab (NGINX) ──────────────────────────────────────
resource "google_compute_instance" "gcelab" {
  depends_on   = [google_project_service.compute]
  name         = "gcelab"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  tags = ["http-server"]

  metadata_startup_script = <<-EOF
    apt-get update -y -qq
    apt-get install -y -qq nginx
    systemctl enable nginx
    systemctl start nginx
  EOF
}

# ── VM: gcelab2 ─────────────────────────────────────────────
resource "google_compute_instance" "gcelab2" {
  depends_on   = [google_project_service.compute]
  name         = "gcelab2"
  machine_type = var.machine_type
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
}
