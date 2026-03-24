variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-east4"
}

variable "memory" {
  description = "Memory allocation for the function"
  type        = string
  default     = "512M"
}
