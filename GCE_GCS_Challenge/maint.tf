provider "google" {
  project = "my-user-project-331814"
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_storage_bucket" "bucket" {
  name     = "kfinn-gce-challenge"
  location = "us-central1"
  project  = "my-user-project-331814"
}

resource "google_service_account" "service_account" {
  account_id   = "gce-challenge-sa"
  display_name = "Service Account"
  project      = "my-user-project-331814"
}

resource "google_project_iam_member" "service_account_permissions" {
  project = "my-user-project-331814"
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.service_account.email}"
}


resource "google_compute_instance" "compute_vm" {
  name         = "gce-challenge-vm"
  machine_type = "e2-micro"
  zone         = "us-central1-c"

  tags = ["created", "terraform"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = "default"
  }

  metadata = {
    lab-logs-bucket = "gs://${google_storage_bucket.bucket.name}"
  }

  #metadata_startup_script = file("startup_script.sh")

  service_account {
    email  = google_service_account.service_account.email
    scopes = ["storage-rw"]
  }
}