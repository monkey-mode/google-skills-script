output "bq_dataset" {
  value = google_bigquery_dataset.scc_findings.dataset_id
}
