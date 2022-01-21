provider "google" {
  credentials = file("C:/Users/kieran.finn/Documents/gcp_keys/network-challenge-terraform-sa.json")
  project     = var.gcp_project
  region      = var.gcp_region
  zone        = var.gcp_zone
}


resource "google_service_account" "backend_service_account" {
  account_id   = "backend-sa"
  display_name = "Backend"
  project      = var.gcp_project
}

resource "google_service_account" "frontend_service_account" {
  account_id   = "frontend-sa"
  display_name = "Frontend"
  project      = var.gcp_project
}

resource "google_compute_network" "vpc_network" {
  name = "vpc-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "iowa_subnet" {
  name          = "iowa-subnet"
  ip_cidr_range = "192.168.10.0/24"
  region        = var.gcp_region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "b2b_ingress" {
  name      = "b2b-ingress"
  network   = google_compute_network.vpc_network.name
  direction = "INGRESS"

  allow {
    protocol = "icmp"
  }

  target_service_accounts = [google_service_account.backend_service_account.name]
  source_service_accounts = [google_service_account.backend_service_account.name]
}

resource "google_compute_firewall" "b2b_egress" {
  name      = "b2b-egress"
  network   = google_compute_network.vpc_network.name
  direction = "EGRESS"

  allow {
    protocol = "icmp"
  }

  target_service_accounts = [google_service_account.backend_service_account.name]
  destination_ranges      = [google_compute_subnetwork.iowa_subnet.ip_cidr_range]
}

resource "google_compute_firewall" "deny_backend_egress" {
  name      = "deny-backend-egress"
  network   = google_compute_network.vpc_network.name
  direction = "EGRESS"

  deny {
    protocol = "icmp"
  }

  target_service_accounts = [google_service_account.backend_service_account.name]
  priority                = 65534
}

resource "google_compute_firewall" "f2b_ingress" {
  name      = "f2b-ingress"
  network   = google_compute_network.vpc_network.name
  direction = "INGRESS"

  allow {
    protocol = "icmp"
  }

  target_service_accounts = [google_service_account.backend_service_account.name]
  source_service_accounts = [google_service_account.frontend_service_account.name]
}

resource "google_compute_firewall" "allow_frontend_ingress" {
  name      = "allow-frontend-ingress"
  network   = google_compute_network.vpc_network.name
  direction = "INGRESS"

  allow {
    protocol = "icmp"
  }

  target_service_accounts = [google_service_account.frontend_service_account.name]
  source_ranges           = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_ssh" {
  name      = "allow-ssh"
  network   = google_compute_network.vpc_network.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["open-ssh"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance_template" "frontend_template" {
  name        = "frontend-template"
  description = "template for the frontend"

  machine_type = "e2-micro"

  tags = ["open-ssh"]

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2004-lts"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.iowa_subnet.name

    access_config {
      // Include this section to give the VM an external ip address
    }
  }


  service_account {
    email  = google_service_account.frontend_service_account.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance_template" "backend_template" {
  name        = "backend-template"
  description = "template for the backend"

  machine_type = "e2-micro"

  tags = ["open-ssh"]

  disk {
    source_image = "ubuntu-os-cloud/ubuntu-2004-lts"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.iowa_subnet.name

    access_config {
      // Include this section to give the VM an external ip address
    }
  }


  service_account {
    email  = google_service_account.backend_service_account.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_region_instance_group_manager" "backend_ig" {
  name               = "backend-ig"
  base_instance_name = "backend-vm"
  region             = var.gcp_region

  version {
    name              = "backend-ig-version"
    instance_template = google_compute_instance_template.backend_template.id
  }
  lifecycle {
    ignore_changes = [target_size,]
  }
}


resource "google_compute_region_autoscaler" "backend_autoscaler" {
  name   = "backend-autoscaler"
  region = var.gcp_region
  target = google_compute_region_instance_group_manager.backend_ig.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
  
}

resource "google_compute_region_instance_group_manager" "frontend_ig" {
  name               = "frontend-ig"
  base_instance_name = "frontend-vm"
  region             = var.gcp_region

  version {
    name              = "frontend-ig-version"
    instance_template = google_compute_instance_template.frontend_template.id
  }
  lifecycle {
    ignore_changes = [target_size,]
  }
}


resource "google_compute_region_autoscaler" "frontend_autoscaler" {
  name   = "frontend-autoscaler"
  region = var.gcp_region
  target = google_compute_region_instance_group_manager.frontend_ig.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}