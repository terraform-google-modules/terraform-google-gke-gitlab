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

terraform {
  required_version = ">= 0.12.0"
}

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
    host                   = "${google_container_cluster.gitlab.endpoint}"
    client_certificate     = "${base64decode(google_container_cluster.gitlab.master_auth.0.client_certificate)}"
    client_key             = "${base64decode(google_container_cluster.gitlab.master_auth.0.client_key)}"
    cluster_ca_certificate = "${base64decode(google_container_cluster.gitlab.master_auth.0.cluster_ca_certificate)}"
  }
}

provider "kubernetes" {
  host                   = "${google_container_cluster.gitlab.endpoint}"
  client_certificate     = "${base64decode(google_container_cluster.gitlab.master_auth.0.client_certificate)}"
  client_key             = "${base64decode(google_container_cluster.gitlab.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.gitlab.master_auth.0.cluster_ca_certificate)}"
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
  ip_cidr_range = "10.0.0.0/16"
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

// Database
resource "google_compute_global_address" "gitlab_sql" {
  provider      = "google-beta"
  project       = "${var.project_id}"
  name          = "gitlab-sql"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  network       = "${google_compute_network.gitlab.self_link}"
  prefix_length = 16
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = "google-beta"
  network                 = "${google_compute_network.gitlab.self_link}"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = ["${google_compute_global_address.gitlab_sql.name}"]
}

resource "google_sql_database_instance" "gitlab_db" {
  depends_on       = ["google_service_networking_connection.private_vpc_connection"]
  name             = "gitlab-db"
  region           = "${var.region}"
  database_version = "POSTGRES_9_6"

  settings {
    tier            = "db-custom-4-15360"
    disk_autoresize = true

    ip_configuration {
      ipv4_enabled    = "false"
      private_network = "${google_compute_network.gitlab.self_link}"
    }
  }
}

resource "google_sql_database" "gitlabhq_production" {
  name     = "gitlabhq_production"
  instance = "${google_sql_database_instance.gitlab_db.name}"
}

resource "random_string" "autogenerated_gitlab_db_password" {
  length  = 16
  special = false
}

resource "google_sql_user" "gitlab" {
  name     = "gitlab"
  instance = "${google_sql_database_instance.gitlab_db.name}"

  password = "${var.gitlab_db_password != "" ? var.gitlab_db_password : random_string.autogenerated_gitlab_db_password.result}"
}

// Redis
resource "google_redis_instance" "gitlab" {
  name               = "gitlab"
  tier               = "STANDARD_HA"
  memory_size_gb     = 5
  region             = "${var.region}"
  authorized_network = "${google_compute_network.gitlab.self_link}"

  depends_on = ["google_project_service.redis"]

  location_id             = "${var.region}-a"
  alternative_location_id = "${var.region}-f"
  display_name            = "GitLab Redis"
}

// Cloud Storage
resource "google_storage_bucket" "gitlab-uploads" {
  name     = "${var.project_id}-uploads"
  location = "${var.region}"
}

resource "google_storage_bucket" "gitlab-artifacts" {
  name     = "${var.project_id}-artifacts"
  location = "${var.region}"
}

resource "google_storage_bucket" "gitlab-lfs" {
  name     = "${var.project_id}-lfs"
  location = "${var.region}"
}

resource "google_storage_bucket" "gitlab-packages" {
  name     = "${var.project_id}-packages"
  location = "${var.region}"
}

resource "google_storage_bucket" "gitlab-registry" {
  name     = "${var.project_id}-registry"
  location = "${var.region}"
}

// GKE Cluster
resource "google_container_cluster" "gitlab" {
  project            = "${var.project_id}"
  name               = "gitlab"
  location           = "${var.region}"
  min_master_version = "1.11"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true

  initial_node_count = 1

  network    = "${google_compute_network.gitlab.self_link}"
  subnetwork = "${google_compute_subnetwork.us-central.self_link}"

  ip_allocation_policy {
    # Allocate ranges automatically
    cluster_ipv4_cidr_block  = ""
    services_ipv4_cidr_block = ""
  }

  enable_legacy_abac = true

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  depends_on = ["google_project_service.gke"]
}

resource "google_container_node_pool" "gitlab" {
  name       = "gitlab"
  location   = "${var.region}"
  cluster    = "${google_container_cluster.gitlab.name}"
  node_count = 1
  depends_on = []

  node_config {
    preemptible  = false
    machine_type = "n1-standard-4"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller-admin" {
  metadata {
    name = "tiller-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_storage_class" "pd-ssd" {
  metadata {
    name = "pd-ssd"
  }

  storage_provisioner = "kubernetes.io/gce-pd"

  parameters = {
    type = "pd-ssd"
  }
}

resource "kubernetes_secret" "gitlab_pg" {
  metadata {
    name = "gitlab-pg"
  }

  data = {
    password = "${var.gitlab_db_password != "" ? var.gitlab_db_password : random_string.autogenerated_gitlab_db_password.result}"
  }
}

resource "kubernetes_secret" "gitlab_rails_storage" {
  metadata {
    name = "gitlab-rails-storage"
  }

  data = {
    connection = <<EOT
provider: Google
google_project: ${var.project_id}
google_client_email: ${google_service_account.gitlab_gcs.email}
google_json_key_string: '${base64decode(google_service_account_key.gitlab_gcs.private_key)}'
EOT
  }
}

resource "kubernetes_secret" "gitlab_gcs_credentials" {
  metadata {
    name = "google-application-credentials"
  }

  data = {
    gcs-application-credentials-file = "${base64decode(google_service_account_key.gitlab_gcs.private_key)}"
  }
}

data "helm_repository" "gitlab" {
  name = "gitlab"
  url  = "https://charts.gitlab.io"
}

data "template_file" "helm_values" {
  template = "${file("${path.module}/values.yaml.tpl")}"

  vars = {
    INGRESS_IP         = "${google_compute_address.gitlab.address}"
    DB_PRIVATE_IP      = "${google_sql_database_instance.gitlab_db.private_ip_address}"
    REDIS_PRIVATE_IP   = "${google_redis_instance.gitlab.host}"
    PROJECT_ID         = "${var.project_id}"
    CERT_MANAGER_EMAIL = "${var.certmanager_email}"
  }
}

resource "helm_release" "gitlab" {
  name       = "gitlab"
  repository = "${data.helm_repository.gitlab.name}"
  chart      = "gitlab"
  version    = "1.7.1"
  timeout    = 600

  values = ["${data.template_file.helm_values.rendered}"]

  depends_on = ["google_redis_instance.gitlab",
    "google_sql_database.gitlabhq_production",
    "google_sql_user.gitlab",
    "kubernetes_cluster_role_binding.tiller-admin",
    "kubernetes_storage_class.pd-ssd",
  ]
}
