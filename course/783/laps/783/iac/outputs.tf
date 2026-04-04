output "cluster_name" {
  value = google_container_cluster.autopilot.name
}

output "get_credentials_command" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.autopilot.name} --region=${var.region}"
}
