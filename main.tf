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
  project = var.project_id
  region  = var.region
}

locals {
  gitlab_db_name = var.gitlab_db_random_prefix ? "${var.gitlab_db_name}-${random_id.suffix[0].hex}" : var.gitlab_db_name
}

resource "random_id" "suffix" {
  count = var.gitlab_db_random_prefix ? 1 : 0

  byte_length = 4
}

# Retrieve an access token
data "google_client_config" "provider" {}

provider "helm" {
  kubernetes {
    cluster_ca_certificate = base64decode(google_container_cluster.gitlab.master_auth[0].cluster_ca_certificate)
    host                   = "https://${google_container_cluster.gitlab.endpoint}"
    token                  = data.google_client_config.provider.access_token
  }
}

provider "kubernetes" {
  cluster_ca_certificate = base64decode(google_container_cluster.gitlab.master_auth[0].cluster_ca_certificate)
  host                   = "https://${google_container_cluster.gitlab.endpoint}"
  token                  = data.google_client_config.provider.access_token
}

// Services
resource "google_project_service" "container" {
  project                    = var.project_id
  service                    = "container.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "cloudresourcemanager" {
  project                    = var.project_id
  service                    = "cloudresourcemanager.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "compute" {
  project                    = var.project_id
  service                    = "compute.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "servicenetworking" {
  project                    = var.project_id
  service                    = "servicenetworking.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "redis" {
  project                    = var.project_id
  service                    = "redis.googleapis.com"
  disable_dependent_services = true
}

// GCS Service Account
resource "google_service_account" "gitlab_gcs" {
  project      = var.project_id
  account_id   = "gitlab-gcs"
  display_name = "GitLab Cloud Storage"
}

resource "google_service_account_key" "gitlab_gcs" {
  service_account_id = google_service_account.gitlab_gcs.name
}

resource "google_project_iam_member" "project" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.gitlab_gcs.email}"
}

// GKE Service Account
resource "google_service_account" "gitlab_gke" {
  account_id   = "gitlab-gke"
  display_name = "Gitlab GKE Service Account"
}

// Networking
resource "google_compute_network" "gitlab" {
  name                    = "gitlab"
  project                 = var.project_id
  auto_create_subnetworks = false
  depends_on = [
    google_project_service.compute,
  ]
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "gitlab"
  ip_cidr_range = var.gitlab_nodes_subnet_cidr
  region        = var.region
  network       = google_compute_network.gitlab.self_link

  secondary_ip_range {
    range_name    = "gitlab-cluster-pod-cidr"
    ip_cidr_range = var.gitlab_pods_subnet_cidr
  }

  secondary_ip_range {
    range_name    = "gitlab-cluster-service-cidr"
    ip_cidr_range = var.gitlab_services_subnet_cidr
  }
}

resource "google_compute_address" "gitlab" {
  name         = "gitlab"
  region       = var.region
  address_type = "EXTERNAL"
  description  = "Gitlab Ingress IP"
  count        = var.gitlab_address_name == "" ? 1 : 0
  depends_on = [
    google_project_service.compute
  ]
}

// Database
resource "google_compute_global_address" "gitlab_sql" {
  project       = var.project_id
  name          = "gitlab-sql"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  network       = google_compute_network.gitlab.self_link
  prefix_length = 16
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.gitlab.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.gitlab_sql.name]
  depends_on              = [google_project_service.servicenetworking]
}

resource "google_sql_database_instance" "gitlab_db" {
  depends_on       = [google_service_networking_connection.private_vpc_connection]
  name             = local.gitlab_db_name
  region           = var.region
  database_version = "POSTGRES_11"

  deletion_protection = !var.allow_force_destroy

  settings {
    tier            = "db-custom-4-15360"
    disk_autoresize = true

    ip_configuration {
      ipv4_enabled    = "false"
      private_network = google_compute_network.gitlab.self_link
    }
  }
}

resource "google_sql_database" "gitlabhq_production" {
  name     = "gitlabhq_production"
  instance = google_sql_database_instance.gitlab_db.name
}

resource "random_string" "autogenerated_gitlab_db_password" {
  length  = 16
  special = false
}

resource "google_sql_user" "gitlab" {
  name     = "gitlab"
  instance = google_sql_database_instance.gitlab_db.name

  password = var.gitlab_db_password != "" ? var.gitlab_db_password : random_string.autogenerated_gitlab_db_password.result
}

// Redis
resource "google_redis_instance" "gitlab" {
  name               = "gitlab"
  tier               = "STANDARD_HA"
  memory_size_gb     = 5
  region             = var.region
  authorized_network = google_compute_network.gitlab.self_link

  depends_on = [google_project_service.redis]

  display_name = "GitLab Redis"
}

// Cloud Storage
resource "google_storage_bucket" "gitlab-backups" {
  name          = "${var.project_id}-gitlab-backups"
  location      = var.region
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "gitlab-uploads" {
  name          = "${var.project_id}-gitlab-uploads"
  location      = var.region
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "gitlab-artifacts" {
  name          = "${var.project_id}-gitlab-artifacts"
  location      = var.region
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "git-lfs" {
  name          = "${var.project_id}-git-lfs"
  location      = var.region
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "gitlab-packages" {
  name          = "${var.project_id}-gitlab-packages"
  location      = var.region
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "gitlab-registry" {
  name          = "${var.project_id}-registry"
  location      = var.region
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "gitlab-pseudo" {
  name          = "${var.project_id}-pseudo"
  location      = var.region
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "gitlab-runner-cache" {
  name          = "${var.project_id}-runner-cache"
  location      = var.region
  force_destroy = var.allow_force_destroy
}

# GKE cluster
resource "google_container_cluster" "gitlab" {
  name     = "gitlab"
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.gitlab.name
  subnetwork = google_compute_subnetwork.subnetwork.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "gitlab-cluster-pod-cidr"
    services_secondary_range_name = "gitlab-cluster-service-cidr"
  }

  enable_shielded_nodes = true

  release_channel {
    channel = var.gke_release_channel
  }

  depends_on = [
    google_project_service.compute,
    google_project_service.container,
    google_project_service.cloudresourcemanager
  ]
}

# Separately Managed Node Pool
resource "google_container_node_pool" "gitlab_nodes" {
  name       = "${google_container_cluster.gitlab.name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.gitlab.name
  node_count = var.gke_min_node_count

  node_config {
    service_account = google_service_account.gitlab_gke.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    preemptible  = var.gke_preemptible_nodes
    machine_type = var.gke_machine_type

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = var.gke_min_node_count
    max_node_count = var.gke_max_node_count
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
    password = var.gitlab_db_password != "" ? var.gitlab_db_password : random_string.autogenerated_gitlab_db_password.result
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

resource "kubernetes_secret" "gitlab_registry_storage" {
  metadata {
    name = "gitlab-registry-storage"
  }

  data = {
    "gcs.json" = <<EOT
${base64decode(google_service_account_key.gitlab_gcs.private_key)}
EOT
    storage    = <<EOT
gcs:
  bucket: ${var.project_id}-registry
  keyfile: /etc/docker/registry/storage/gcs.json
EOT
  }
}

resource "kubernetes_secret" "gitlab_gcs_credentials" {
  metadata {
    name = "google-application-credentials"
  }

  data = {
    gcs-application-credentials-file = base64decode(google_service_account_key.gitlab_gcs.private_key)
  }
}

data "google_compute_address" "gitlab" {
  name   = var.gitlab_address_name
  region = var.region

  # Do not get data if the address is being created as part of the run
  count = var.gitlab_address_name == "" ? 0 : 1
}

locals {
  gitlab_address = var.gitlab_address_name == "" ? google_compute_address.gitlab.0.address : data.google_compute_address.gitlab.0.address
  domain         = var.domain != "" ? var.domain : "${local.gitlab_address}.nip.io"
}

data "template_file" "helm_values" {
  template = file("${path.module}/values.yaml.tpl")

  vars = {
    DOMAIN                = local.domain
    INGRESS_IP            = local.gitlab_address
    DB_PRIVATE_IP         = google_sql_database_instance.gitlab_db.private_ip_address
    REDIS_PRIVATE_IP      = google_redis_instance.gitlab.host
    PROJECT_ID            = var.project_id
    CERT_MANAGER_EMAIL    = var.certmanager_email
    GITLAB_RUNNER_INSTALL = var.gitlab_runner_install
  }
}

resource "helm_release" "gitlab" {
  name       = "gitlab"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab"
  version    = var.helm_chart_version
  timeout    = 1200

  values = [data.template_file.helm_values.rendered]

  depends_on = [
    google_redis_instance.gitlab,
    google_sql_user.gitlab,
    kubernetes_storage_class.pd-ssd,
    kubernetes_secret.gitlab_pg,
    kubernetes_secret.gitlab_rails_storage,
    kubernetes_secret.gitlab_registry_storage,
    kubernetes_secret.gitlab_gcs_credentials,
    google_container_node_pool.gitlab_nodes,
  ]
}
