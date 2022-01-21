variable "gcp_project" {
  description = "gcp Project ID"
  type        = string
}

variable "gcp_region" {
  description = "default gcp region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "default gcp zone"
  type        = string
  default     = "us-central1-c"
}