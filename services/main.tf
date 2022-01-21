provider "google" {
  credentials = file("C:/Users/kiera/GCP_credentials/zed-tools-705bc446fdaa.json")
  project     = var.gcp_project
  region      = var.gcp_region
  zone        = var.gcp_zone
}

resource "google_project_service" "cloud_resource_manager_service" {
  project = var.gcp_project
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "compute_service" {
  project = var.gcp_project
  service = "compute.googleapis.com"
}

resource "google_project_service" "iam_service" {
  project                    = var.gcp_project
  service                    = "iam.googleapis.com"
}

resource "google_project_service" "iam_credentials_service" {
  project = var.gcp_project
  service = "iamcredentials.googleapis.com"
  depends_on = [
    google_project_service.iam_service
  ]
  disable_dependent_services = true
}

resource "google_project_service" "secret_manager_service" {
  project = var.gcp_project
  service = "secretmanager.googleapis.com"
}