variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-east1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-east1-c"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "hello-cluster"
}

variable "node_count" {
  description = "Number of nodes per zone"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Node machine type"
  type        = string
  default     = "e2-medium"
}
