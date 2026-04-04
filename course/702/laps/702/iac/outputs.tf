output "service_account_email" {
  value = google_service_account.my_sa.email
}

output "custom_role_id" {
  value = google_project_iam_custom_role.compute_viewer.id
}
