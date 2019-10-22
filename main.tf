/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

provider "google" {
  project = "${var.project_id}"
}

provider "google-beta" {
  project = "${var.project_id}"
}

provider "helm" {
  service_account = "tiller"
  install_tiller  = true
  namespace       = "kube-system"

  kubernetes {
    insecure               = true
    host                   = "${google_container_cluster.gitlab.endpoint}"
    client_certificate     = "${base64decode(google_container_cluster.gitlab.master_auth.0.client_certificate)}"
    client_key             = "${base64decode(google_container_cluster.gitlab.master_auth.0.client_key)}"
//    cluster_ca_certificate = "${base64decode(google_container_cluster.gitlab.master_auth.0.cluster_ca_certificate)}"
  }
}

provider "kubernetes" {
  insecure               = true
  load_config_file       = false
  host                   = "${google_container_cluster.gitlab.endpoint}"
  client_certificate     = "${base64decode(google_container_cluster.gitlab.master_auth.0.client_certificate)}"
  client_key             = "${base64decode(google_container_cluster.gitlab.master_auth.0.client_key)}"
//  cluster_ca_certificate = "${base64decode(google_container_cluster.gitlab.master_auth.0.cluster_ca_certificate)}"
}

// IAM
resource "google_project_service" "compute" {
  project            = "${var.project_id}"
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "gke" {
  project            = "${var.project_id}"
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "service_networking" {
  project            = "${var.project_id}"
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager" {
  project            = "${var.project_id}"
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "redis" {
  project            = "${var.project_id}"
  service            = "redis.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "gitlab_gcs" {
  project      = "${var.project_id}"
  account_id   = "gitlab-gcs"
  display_name = "GitLab Cloud Storage"
}

resource "google_service_account_key" "gitlab_gcs" {
  service_account_id = "${google_service_account.gitlab_gcs.name}"
}

resource "google_project_iam_member" "project" {
  project = "${var.project_id}"
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.gitlab_gcs.email}"
}

// Networking
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

// Redis
resource "google_redis_instance" "gitlab" {
  name               = "gitlab"
  tier               = "${var.redis_tier}"
  memory_size_gb     = "${var.redis_size_gb}"
  region             = "${var.region}"
  authorized_network = "${google_compute_network.gitlab.self_link}"

  depends_on = ["google_project_service.redis"]

  location_id             = "${var.region}-a"
  alternative_location_id = "${var.region}-c"
  display_name            = "GitLab Redis"
}


