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
}

provider "google-beta" {
  project = var.project_id
}

locals {
  gitlab_db_name = var.gitlab_db_random_prefix ? "${var.gitlab_db_name}-${random_id.suffix[0].hex}" : var.gitlab_db_name
}

resource "random_id" "suffix" {
  count = var.gitlab_db_random_prefix ? 2 : 1

  byte_length = 4
}

# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

provider "helm" {
  kubernetes {
    host                   = "https://${module.gke.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  }
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

# Services
module "project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "~> 13.0"

  project_id                  = var.project_id
  disable_services_on_destroy = false

  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "redis.googleapis.com",
  ]
}

# GCS Service Account
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

# Networking
resource "google_compute_network" "gitlab" {
  name                    = "gitlab"
  project                 = module.project_services.project_id
  auto_create_subnetworks = false
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
  depends_on   = [module.project_services.project_id]
  count        = var.gitlab_address_name == "" ? 1 : 0
}

module "cloud_nat" {
  source      = "terraform-google-modules/cloud-nat/google"
  version     = "~> 2.2.0"
  project_id  = var.project_id
  region      = var.region
  router      = format("%s-router", var.project_id)
  name        = "${var.project_id}-cloud-nat-${random_id.suffix[1].hex}"
  network     = google_compute_network.gitlab.self_link
  nat_ips     = [var.gitlab_address_name == "" ? google_compute_address.gitlab[0].self_link : data.google_compute_address.gitlab[0].self_link]
  create_router     = true
  min_ports_per_vm  = "2048"
  depends_on = [
    google_compute_address.gitlab,
  ]
}

# Database
resource "google_compute_global_address" "gitlab_sql" {
  provider      = google-beta
  project       = var.project_id
  name          = "gitlab-sql"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  network       = google_compute_network.gitlab.self_link
  address       = "10.1.0.0"
  prefix_length = 16
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = google_compute_network.gitlab.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.gitlab_sql.name]
  depends_on              = [module.project_services.project_id]
}

resource "google_sql_database_instance" "gitlab_db" {
  depends_on           = [google_service_networking_connection.private_vpc_connection]
  name                 = local.gitlab_db_name
  region               = var.region
  database_version     = var.postgresql_version
  deletion_protection  = var.postgresql_del_protection

  settings {
    tier               = var.postgresql_tier
    availability_type  = var.postgresql_availability_type
    disk_size          = var.postgresql_disk_size
    disk_type          = var.postgresql_disk_type
    disk_autoresize    = true

    ip_configuration {
      ipv4_enabled    = "false"
      private_network = google_compute_network.gitlab.self_link
      require_ssl     = "true"
    }

    backup_configuration {
      enabled                        = var.postgresql_enable_backup
      start_time                     = var.postgresql_backup_start_time
      point_in_time_recovery_enabled = true
        backup_retention_settings {
          retained_backups           = var. postgresql_backup_retained_count
        }
    }

    maintenance_window {
      day          = 7
      hour         = 2
      update_track = "stable"
    }
  }
}

resource "google_sql_ssl_cert" "postgres_client_cert" {
  common_name = "gitlab.${var.domain}"
  instance    = google_sql_database_instance.gitlab_db.name
  project     = var.project_id
}

resource "google_sql_database" "gitlabhq_production" {
  name       = "gitlabhq_production"
  instance   = google_sql_database_instance.gitlab_db.name
  depends_on = [google_sql_user.gitlab]
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

# Redis
resource "google_redis_instance" "gitlab" {
  name               = "gitlab"
  tier               = var.redis_tier
  memory_size_gb     = var.redis_size
  region             = var.region
  authorized_network = google_compute_network.gitlab.self_link

  depends_on = [module.project_services.project_id]

  display_name = "GitLab Redis"
}

# Cloud Storage
resource "google_storage_bucket" "gitlab_backups" {
  name          = "${var.project_id}-gitlab-backups"
  location      = var.region
  storage_class = var.bucket_storage_class
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "gitlab_tmp_backups" {
  name          = "${var.project_id}-gitlab-tmp-backups"
  location      = var.region
  storage_class = var.bucket_storage_class
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "gitlab_uploads" {
  name          = "${var.project_id}-gitlab-uploads"
  location      = var.region
  storage_class = var.bucket_storage_class
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "gitlab_artifacts" {
  name          = "${var.project_id}-gitlab-artifacts"
  location      = var.region
  storage_class = var.bucket_storage_class
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "git_lfs" {
  name          = "${var.project_id}-git-lfs"
  location      = var.region
  storage_class = var.bucket_storage_class
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "gitlab_packages" {
  name          = "${var.project_id}-gitlab-packages"
  location      = var.region
  storage_class = var.bucket_storage_class
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "gitlab_registry" {
  name          = "${var.project_id}-gitlab-registry"
  location      = var.region
  storage_class = var.bucket_storage_class
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "gitlab_pseudo" {
  name          = "${var.project_id}-pseudo"
  location      = var.region
  storage_class = var.bucket_storage_class
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "gitlab_runner_cache" {
  name          = "${var.project_id}-runner-cache"
  location      = var.region
  storage_class = var.bucket_storage_class
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "gitlab_dependency_proxy" {
  name          = "${var.project_id}-dependency-proxy"
  location      = var.region
  storage_class = var.bucket_storage_class
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "gitlab_terraform_state" {
  name          = "${var.project_id}-terraform-state"
  location      = var.region
  storage_class = var.bucket_storage_class
  force_destroy = var.allow_force_destroy
}

resource "google_storage_bucket" "gitlab_external_diffs" {
  name          = "${var.project_id}-gitlab-external-diffs"
  location      = var.region
  storage_class = var.bucket_storage_class
  force_destroy = var.allow_force_destroy
}

# GKE Cluster
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version = "~> 20.0"

  # Create an implicit dependency on service activation
  project_id = module.project_services.project_id

  name                          = "gitlab"
  region                        = var.region
  regional                      = true
  kubernetes_version            = var.gke_version

  network                       = google_compute_network.gitlab.name
  subnetwork                    = google_compute_subnetwork.subnetwork.name
  ip_range_pods                 = "gitlab-cluster-pod-cidr"
  ip_range_services             = "gitlab-cluster-service-cidr"

  enable_private_endpoint       = false
  enable_private_nodes          = true
  release_channel               = "STABLE"
  maintenance_start_time        = "03:00"
  network_policy                = false
  enable_shielded_nodes         = true
  dns_cache                     = true

  remove_default_node_pool      = true

  
  node_pools = [
    {
      name                       = "gitlab"
      description                = "Gitlab Cluster"
      machine_type               = var.gke_machine_type
      node_count                 = 1
      min_count                  = var.gke_min_node_count
      max_count                  = var.gke_max_node_count
      disk_size_gb               = 100
      disk_type                  = "pd-standard"
      image_type                 = "COS_CONTAINERD"
      auto_repair                = true
      auto_upgrade               = true
      cloudrun                   = var.gke_enable_cloudrun
      enable_pod_security_policy = false
      preemptible                = false
      autoscaling                = true 
    },
  ]

  node_pools_oauth_scopes = {
    all = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "kubernetes_storage_class" "storage_class" {
  metadata {
    name = var.gke_storage_class
  }

  storage_provisioner = "kubernetes.io/gce-pd"

  parameters = {
    type = var.gke_storage_class
    replication-type = var.gke_disk_replication
  }

  depends_on = [time_sleep.sleep_for_cluster_fix_helm_6361]
}

resource "kubernetes_secret" "gitlab_pg" {
  metadata {
    name = "gitlab-pg"
  }

  data = {
    password = var.gitlab_db_password != "" ? var.gitlab_db_password : random_string.autogenerated_gitlab_db_password.result
  }

  depends_on = [time_sleep.sleep_for_cluster_fix_helm_6361]
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

  depends_on = [time_sleep.sleep_for_cluster_fix_helm_6361]
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

  depends_on = [time_sleep.sleep_for_cluster_fix_helm_6361]
}


resource "kubernetes_secret" "gitlab_gcs_credentials" {
  metadata {
    name = "google-application-credentials"
  }

  data = {
    gcs-application-credentials-file = base64decode(google_service_account_key.gitlab_gcs.private_key)
  }

  depends_on = [time_sleep.sleep_for_cluster_fix_helm_6361]
}


resource "kubernetes_secret" "postgresql_mtls_secret" {
  metadata {
    name = "gitlab-postgres-mtls"
  }

  data = {
    cert              = google_sql_ssl_cert.postgres_client_cert.cert
    private_key       = google_sql_ssl_cert.postgres_client_cert.private_key
    server_ca_cert    = google_sql_ssl_cert.postgres_client_cert.server_ca_cert
  }

  depends_on = [time_sleep.sleep_for_cluster_fix_helm_6361]
}

data "google_compute_address" "gitlab" {
  name   = var.gitlab_address_name
  region = var.region

  # Do not get data if the address is being created as part of the run
  count = var.gitlab_address_name == "" ? 0 : 1
}

locals {
  gitlab_address     = var.gitlab_address_name == "" ? google_compute_address.gitlab[0].address : data.google_compute_address.gitlab[0].address
  domain             = var.domain != "" ? var.domain : "${local.gitlab_address}.xip.io"
  gitlab_smtp_user   = var.gitlab_enable_smtp != false ? var.gitlab_smtp_user : ""
}

data "template_file" "helm_values" {
  template = file("${path.module}/values.yaml")

  vars = {
    DOMAIN                = local.domain
    INGRESS_IP            = local.gitlab_address
    DB_PRIVATE_IP         = google_sql_database_instance.gitlab_db.private_ip_address
    REDIS_PRIVATE_IP      = google_redis_instance.gitlab.host
    PROJECT_ID            = var.project_id
    ENABLE_CERT_MANAGER   = var.gitlab_enable_certmanager
    CERT_MANAGER_EMAIL    = var.certmanager_email
    INSTALL_RUNNER        = var.gitlab_install_runner
    INSTALL_INGRESS_NGINX = var.gitlab_install_ingress_nginx
    INSTALL_PROMETHEUS    = var.gitlab_install_prometheus
    INSTALL_GRAFANA       = var.gitlab_install_grafana
    INSTALL_KAS           = var.gitlab_install_kas
    ENABLE_REGISTRY       = var.gitlab_enable_registry
    ENABLE_CRON_BACKUP    = var.gitlab_enable_cron_backup
    SCHEDULE_CRON_BACKUP  = var.gitlab_schedule_cron_backup
    GITALY_PV_SIZE        = var.gitlab_gitaly_disk_size
    PV_STORAGE_CLASS      = var.gke_storage_class 
    ENABLE_SMTP           = var.gitlab_enable_smtp
    SMTP_USER             = local.gitlab_smtp_user 
    BACKUP_EXTRA          = var.gitlab_backup_extra_args

    # HPA settings for cost/performance optimization
    HPA_MIN_REPLICAS_REGISTRY   = var.gitlab_hpa_min_replicas_registry
    HPA_MAX_REPLICAS_REGISTRY   = var.gitlab_hpa_max_replicas_registry
    HPA_MIN_REPLICAS_WEBSERVICE = var.gitlab_hpa_min_replicas_webservice
    HPA_MAX_REPLICAS_WEBSERVICE = var.gitlab_hpa_max_replicas_webservice
    HPA_MIN_REPLICAS_SIDEKIQ    = var.gitlab_hpa_min_replicas_sidekiq
    HPA_MAX_REPLICAS_SIDEKIQ    = var.gitlab_hpa_max_replicas_sidekiq
    HPA_MIN_REPLICAS_KAS        = var.gitlab_hpa_min_replicas_kas
    HPA_MAX_REPLICAS_KAS        = var.gitlab_hpa_max_replicas_kas
    HPA_MIN_REPLICAS_SHELL      = var.gitlab_hpa_min_replicas_shell
    HPA_MAX_REPLICAS_SHELL      = var.gitlab_hpa_max_replicas_shell

  }
}

resource "time_sleep" "sleep_for_cluster_fix_helm_6361" {
  create_duration  = "180s"
  destroy_duration = "180s"
  depends_on       = [module.gke.endpoint, google_sql_database.gitlabhq_production]
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
    kubernetes_storage_class.storage_class,
    kubernetes_secret.gitlab_pg,
    kubernetes_secret.gitlab_rails_storage,
    kubernetes_secret.gitlab_registry_storage,
    kubernetes_secret.gitlab_gcs_credentials,
    time_sleep.sleep_for_cluster_fix_helm_6361,
    module.cloud_nat,
  ]
}
