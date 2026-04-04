output "bucket_name" {
  value = google_storage_bucket.api_demo.name
}

output "bucket_url" {
  value = "https://storage.googleapis.com/${google_storage_bucket.api_demo.name}"
}
