# Networking

resource "google_compute_network" "gitlab" {
  name                    = "gitlab"
  project                 = "${var.project_id}"
  auto_create_subnetworks = false
  depends_on              = ["google_project_service.compute"]
}

resource "google_compute_subnetwork" "us-central" {
  name          = "gitlab"
  ip_cidr_range = "${var.network_cidr}"
  region        = "${var.region}"
  network       = "${google_compute_network.gitlab.self_link}"
}

resource "google_compute_address" "gitlab" {
  name         = "gitlab"
  region       = "${var.region}"
  address_type = "EXTERNAL"
  description  = "Gitlab Ingress IP"
  depends_on   = ["google_project_service.compute"]
}

