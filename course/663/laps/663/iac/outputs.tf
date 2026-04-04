output "cluster_name" {
  value = google_container_cluster.hello_cluster.name
}

output "cluster_endpoint" {
  value     = google_container_cluster.hello_cluster.endpoint
  sensitive = true
}

output "artifact_registry_url" {
  value = "${var.region}-docker.pkg.dev/${google_artifact_registry_repository.hello_repo.project}/${google_artifact_registry_repository.hello_repo.repository_id}"
}

output "get_credentials_command" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.hello_cluster.name} --zone=${var.zone}"
}
