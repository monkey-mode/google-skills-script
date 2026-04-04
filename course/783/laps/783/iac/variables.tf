variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "GKE Autopilot cluster name"
  type        = string
  default     = "autopilot-cluster-1"
}
