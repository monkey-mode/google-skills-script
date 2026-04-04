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

data "google_project" "current" {}

locals {
  project_id     = data.google_project.current.project_id
  sa_email       = "${google_service_account.security_lab.email}"
  subnet_range   = "10.10.0.0/24"
}

# ── APIs ──────────────────────────────────────────────────
resource "google_project_service" "apis" {
  for_each = toset([
    "iam.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
  ])
  service            = each.value
  disable_on_destroy = false
}

# ── Task 1: Custom IAM role ───────────────────────────────
resource "google_project_iam_custom_role" "security_lab" {
  depends_on  = [google_project_service.apis]
  role_id     = "customSecurityRole"
  title       = "Custom Security Role"
  description = "Custom role for Cloud Security Fundamentals lab"
  permissions = [
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.get",
    "storage.objects.list",
    "compute.instances.get",
    "compute.instances.list",
  ]
}

# ── Task 2: Service account ───────────────────────────────
resource "google_service_account" "security_lab" {
  depends_on   = [google_project_service.apis]
  account_id   = "security-lab-sa"
  display_name = "Security Lab Service Account"
  description  = "Service account for Cloud Security Fundamentals lab"
}

# ── Task 3: Bind roles to service account ─────────────────
resource "google_project_iam_member" "custom_role_binding" {
  project = local.project_id
  role    = google_project_iam_custom_role.security_lab.id
  member  = "serviceAccount:${google_service_account.security_lab.email}"
}

resource "google_project_iam_member" "viewer_binding" {
  project = local.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.security_lab.email}"
}

# ── Task 4: Cloud KMS key ring and key ────────────────────
resource "google_kms_key_ring" "security_lab" {
  depends_on = [google_project_service.apis]
  name       = "security-lab-keyring"
  location   = var.region
}

resource "google_kms_crypto_key" "security_lab" {
  name     = "security-lab-key"
  key_ring = google_kms_key_ring.security_lab.id
  purpose  = "ENCRYPT_DECRYPT"
}

# ── Task 6: Custom VPC network ────────────────────────────
resource "google_compute_network" "security_lab" {
  depends_on              = [google_project_service.apis]
  name                    = "security-lab-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "security_lab" {
  name                     = "security-lab-subnet"
  network                  = google_compute_network.security_lab.id
  region                   = var.region
  ip_cidr_range            = local.subnet_range
  private_ip_google_access = true
}

# ── Task 7: Firewall rules ────────────────────────────────
resource "google_compute_firewall" "allow_ssh" {
  name    = "security-lab-allow-ssh"
  network = google_compute_network.security_lab.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges           = ["0.0.0.0/0"]
  target_service_accounts = [google_service_account.security_lab.email]
  description             = "Allow SSH for security lab service account"
}

resource "google_compute_firewall" "allow_internal" {
  name    = "security-lab-allow-internal"
  network = google_compute_network.security_lab.name

  allow { protocol = "tcp" }
  allow { protocol = "udp" }
  allow { protocol = "icmp" }

  source_ranges = [local.subnet_range]
  description   = "Allow internal traffic within subnet"
}
