output "artifact_registry_url" {
  value = "${var.region}-docker.pkg.dev/${google_artifact_registry_repository.serverless_repo.project}/${google_artifact_registry_repository.serverless_repo.repository_id}"
}

output "pubsub_topic" {
  value = google_pubsub_topic.hello_topic.name
}
