output "service_account_email" {
  value = google_service_account.security_lab.email
}

output "custom_role_id" {
  value = google_project_iam_custom_role.security_lab.id
}

output "kms_key_ring" {
  value = google_kms_key_ring.security_lab.name
}

output "kms_key" {
  value = google_kms_crypto_key.security_lab.name
}

output "vpc_network" {
  value = google_compute_network.security_lab.name
}

output "subnet" {
  value = google_compute_subnetwork.security_lab.name
}
