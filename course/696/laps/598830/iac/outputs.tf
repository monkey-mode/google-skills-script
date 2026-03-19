output "function_url" {
  description = "Cloud Run Function URL"
  value       = google_cloudfunctions2_function.gcfunction.service_config[0].uri
}
