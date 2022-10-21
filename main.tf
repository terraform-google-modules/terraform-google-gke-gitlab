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

locals {
  # Postgres DB Name
  gitlab_db_name = var.postgresql_db_random_suffix ? "${var.gitlab_db_name}-${random_id.postgres_suffix[0].hex}" : var.gitlab_db_name

  buckets = [
    "artifacts",
    "runner-cache",
    "backups",
    "dependency-proxy",
    "external-diffs",
    "git-lfs",
    "packages",
    "registry",
    "pseudo",
    "terraform-state",
    "tmp-backups",
    "uploads"
  ]

  subnet_name_pod_cidr     = "gitlab-cluster-pod-cidr"
  subnet_name_service_cidr = "gitlab-cluster-service-cidr"
}

resource "random_id" "postgres_suffix" {
  count       = var.postgresql_db_random_suffix ? 1 : 0
  byte_length = 4
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
    "secretmanager.googleapis.com",
    "containerfilesystem.googleapis.com",
    "storagetransfer.googleapis.com",
    "storage.googleapis.com",
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

# Networking
resource "google_compute_network" "gitlab" {
  name                    = "gitlab"
  project                 = module.project_services.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = "gitlab"
  ip_cidr_range = var.gke_nodes_subnet_cidr
  region        = var.region
  network       = google_compute_network.gitlab.self_link

  secondary_ip_range {
    range_name    = local.subnet_name_pod_cidr
    ip_cidr_range = var.gke_pods_subnet_cidr
  }

  secondary_ip_range {
    range_name    = local.subnet_name_service_cidr
    ip_cidr_range = var.gke_services_subnet_cidr
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

resource "random_id" "cloudnat_suffix" {
  byte_length = 4
}

module "cloud_nat" {
  source           = "terraform-google-modules/cloud-nat/google"
  version          = "~> 2.2.0"
  project_id       = var.project_id
  region           = var.region
  router           = format("%s-router", var.project_id)
  name             = "${var.project_id}-cloud-nat-${random_id.cloudnat_suffix.hex}"
  network          = google_compute_network.gitlab.self_link
  create_router    = true
  min_ports_per_vm = "2048"
}

resource "google_compute_firewall" "admission_webhook" {
  name    = "gitlab-ingress-nginx-admission-webhook"
  network = google_compute_network.gitlab.self_link

  allow {
    protocol = "tcp"
    ports    = ["8443"]
  }
  source_ranges = [module.gke.master_ipv4_cidr_block]
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
  depends_on          = [google_service_networking_connection.private_vpc_connection]
  name                = local.gitlab_db_name
  region              = var.region
  database_version    = var.postgresql_version
  deletion_protection = var.postgresql_del_protection

  settings {
    tier              = var.postgresql_tier
    availability_type = var.postgresql_availability_type
    disk_size         = var.postgresql_disk_size
    disk_type         = var.postgresql_disk_type
    disk_autoresize   = true
    user_labels       = var.gke_cluster_resource_labels

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
        retained_backups = var.postgresql_backup_retained_count
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

resource "google_sql_user" "gitlab" {
  name     = "gitlab"
  instance = google_sql_database_instance.gitlab_db.name
  password = module.gitlab_db_pass.secret_value
}

resource "google_sql_database" "gitlabhq_production" {
  name     = "gitlabhq_production"
  instance = google_sql_database_instance.gitlab_db.name
}

# Redis
resource "google_redis_instance" "gitlab" {
  display_name       = "GitLab Redis"
  name               = "gitlab"
  tier               = var.redis_tier
  memory_size_gb     = var.redis_size
  region             = var.region
  authorized_network = google_compute_network.gitlab.self_link
  redis_configs = {
    "maxmemory-gb" = var.redis_maxmemory_gb
  }

  depends_on = [module.project_services.project_id]
}

# Cloud Storage
resource "random_string" "random_suffix" {
  length  = 4
  upper   = "false"
  lower   = "true"
  numeric = "false"
  special = "false"
}

resource "google_storage_bucket" "gitlab_bucket" {
  for_each = toset(local.buckets)

  name          = "${var.project_id}-gitlab-${each.value}-${random_string.random_suffix.result}"
  location      = var.region
  storage_class = var.gcs_bucket_storage_class
  force_destroy = var.gcs_bucket_allow_force_destroy
  labels        = var.gke_cluster_resource_labels

  versioning {
    enabled = var.gcs_bucket_versioning
  }

  dynamic "lifecycle_rule" {
    for_each = var.gcs_bucket_enable_backup_lifecycle_rule == true && each.value == "backups" ? [1] : []
    content {
      action {
        type          = "SetStorageClass"
        storage_class = var.gcs_bucket_target_storage_class
      }
      condition {
        age                   = var.gcs_bucket_age_backup_sc_change
        matches_storage_class = [var.gcs_bucket_storage_class]
      }
    }
  }
  dynamic "lifecycle_rule" {
    for_each = var.gcs_bucket_enable_backup_lifecycle_rule == true && each.value == "backups" ? [1] : []
    content {
      action {
        type = "Delete"
      }
      condition {
        age                   = var.gcs_bucket_backup_duration
        matches_storage_class = [var.gcs_bucket_target_storage_class]
      }
    }
  }
}

resource "google_storage_bucket_iam_binding" "gitlab_bucket_iam_binding_admin" {
  for_each = google_storage_bucket.gitlab_bucket
  bucket   = each.value.name
  role     = "roles/storage.objectAdmin"
  members = [
    "serviceAccount:${google_service_account.gitlab_gcs.email}"
  ]
}

# GKE Cluster
module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/beta-private-cluster"
  version = "~> 23.0"

  # Create an implicit dependency on service activation
  project_id = module.project_services.project_id

  name               = "gitlab"
  region             = var.region
  regional           = true
  kubernetes_version = var.gke_version

  network           = google_compute_network.gitlab.name
  subnetwork        = google_compute_subnetwork.subnetwork.name
  ip_range_pods     = local.subnet_name_pod_cidr
  ip_range_services = local.subnet_name_service_cidr

  enable_private_endpoint = false
  enable_private_nodes    = true
  release_channel         = "STABLE"
  maintenance_start_time  = "03:00"
  network_policy          = false
  enable_shielded_nodes   = true
  dns_cache               = true

  remove_default_node_pool = true

  # Kube-proxy - eBPF setting 
  datapath_provider = var.gke_datapath
  # Google Group for RBAC
  authenticator_security_group = var.gke_google_group_rbac_mail
  # Backup for GKE 
  gke_backup_agent_config = var.gke_enable_backup_agent
  # Istio 
  istio      = var.gke_enable_istio_addon
  istio_auth = var.gke_istio_auth

  cluster_autoscaling = var.gke_cluster_autoscaling

  node_pools = [
    {
      name                       = "gitlab"
      description                = "Gitlab Cluster"
      machine_type               = var.gke_machine_type
      node_count                 = 1
      min_count                  = var.gke_min_node_count
      max_count                  = var.gke_max_node_count
      disk_size_gb               = 100
      disk_type                  = "pd-balanced"
      image_type                 = "COS_CONTAINERD"
      auto_repair                = true
      auto_upgrade               = true
      cloudrun                   = var.gke_enable_cloudrun
      enable_pod_security_policy = false
      preemptible                = false
      autoscaling                = true

      #Image Streaming
      enable_gcfs = var.gke_enable_image_stream
    },
  ]

  cluster_resource_labels = var.gke_cluster_resource_labels

  node_pools_oauth_scopes = {
    all = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "kubernetes_namespace" "gitlab_namespace" {
  metadata {
    name = var.gitlab_namespace
  }
  depends_on = [time_sleep.sleep_for_cluster_fix_helm_6361]
}

resource "kubernetes_storage_class" "storage_class" {
  metadata {
    name = var.gke_storage_class
  }
  storage_provisioner = "kubernetes.io/gce-pd"
  parameters = {
    type             = var.gke_storage_class
    replication-type = var.gke_disk_replication
  }
  depends_on = [time_sleep.sleep_for_cluster_fix_helm_6361]
}

# Secret for Postgres DB Pass
module "gitlab_db_pass" {
  source          = "./modules/secret_manager"
  project         = var.project_id
  region          = var.region
  secret_id       = var.gcp_existing_db_secret_name
  k8s_namespace   = var.gitlab_namespace
  k8s_secret_name = "gitlab-postgres-secret"
  k8s_secret_key  = "password"

  depends_on = [kubernetes_namespace.gitlab_namespace]
}

# Secret for External Object Storage (LFS, Artifacts, Uploads, etc..)
resource "kubernetes_secret" "gitlab_rails_storage" {
  metadata {
    name      = "gitlab-rails-storage"
    namespace = var.gitlab_namespace
  }

  data = {
    connection = <<EOT
provider: Google
google_project: ${var.project_id}
google_client_email: ${google_service_account.gitlab_gcs.email}
google_json_key_string: '${base64decode(google_service_account_key.gitlab_gcs.private_key)}'
EOT
  }

  depends_on = [kubernetes_namespace.gitlab_namespace]
}

# Secret for Docker Registry on External Object Storage
resource "kubernetes_secret" "gitlab_registry_storage" {
  metadata {
    name      = "gitlab-registry-storage"
    namespace = var.gitlab_namespace
  }

  data = {
    "gcs.json" = <<EOT
${base64decode(google_service_account_key.gitlab_gcs.private_key)}
EOT
    storage    = <<EOT
gcs:
  bucket: ${google_storage_bucket.gitlab_bucket["registry"].name}
  keyfile: /etc/docker/registry/storage/gcs.json
EOT
  }

  depends_on = [kubernetes_namespace.gitlab_namespace]
}

# Secret for Buckup and Runner Cache on External Object Storage
resource "kubernetes_secret" "gitlab_gcs_credentials" {
  metadata {
    name      = "google-application-credentials"
    namespace = var.gitlab_namespace
  }

  data = {
    gcs-application-credentials-file = base64decode(google_service_account_key.gitlab_gcs.private_key)
  }
  depends_on = [kubernetes_namespace.gitlab_namespace]
}

#Secret for Mutual TLS Postgres Implementation
resource "kubernetes_secret" "postgresql_mtls_secret" {
  metadata {
    name      = "gitlab-postgres-mtls"
    namespace = var.gitlab_namespace
  }

  data = {
    cert           = google_sql_ssl_cert.postgres_client_cert.cert
    private_key    = google_sql_ssl_cert.postgres_client_cert.private_key
    server_ca_cert = google_sql_ssl_cert.postgres_client_cert.server_ca_cert
  }
  depends_on = [kubernetes_namespace.gitlab_namespace]
}

#Secret for SMTP Pass
module "gitlab_smtp_pass" {
  source          = "./modules/secret_manager"
  project         = var.project_id
  region          = var.region
  secret_id       = var.gcp_existing_smtp_secret_name
  k8s_namespace   = var.gitlab_namespace
  k8s_secret_name = "gitlab-smtp-secret"
  k8s_secret_key  = "password"

  count      = var.gitlab_enable_smtp ? 1 : 0
  depends_on = [kubernetes_namespace.gitlab_namespace]
}

#Secret for Omniauth Pass
module "gitlab_omniauth_pass" {
  source          = "./modules/secret_manager"
  project         = var.project_id
  region          = var.region
  secret_id       = var.gcp_existing_omniauth_secret_name
  k8s_namespace   = var.gitlab_namespace
  k8s_secret_name = "gitlab-omniauth-secret"
  k8s_secret_key  = "provider"

  count      = var.gitlab_enable_omniauth ? 1 : 0
  depends_on = [kubernetes_namespace.gitlab_namespace]
}

data "google_compute_address" "gitlab" {
  name   = var.gitlab_address_name
  region = var.region

  # Do not get data if the address is being created as part of the run
  count = var.gitlab_address_name == "" ? 0 : 1
}

locals {
  gitlab_address   = var.gitlab_address_name == "" ? google_compute_address.gitlab[0].address : data.google_compute_address.gitlab[0].address
  domain           = var.domain != "" ? var.domain : "${local.gitlab_address}.xip.io"
  gitlab_smtp_user = var.gitlab_enable_smtp != false ? var.gitlab_smtp_user : ""

  monitoring_allowed_cidrs = distinct(
    concat(
      var.gitlab_monitoring_restrict_to_pod_subnet ? ["127.0.0.0/8", var.gke_pods_subnet_cidr] : [],
      length(var.gitlab_monitoring_allowed_cidrs) > 0 ? concat(["127.0.0.0/8", var.gke_pods_subnet_cidr], var.gitlab_monitoring_allowed_cidrs) : []
    )
  )

  gitlab_release_helm_values = templatefile(
    "${path.module}/values.yaml",
    {
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
      TIMEZONE              = var.gitlab_time_zone
      ENABLE_OMNIAUTH       = var.gitlab_enable_omniauth
      ENABLE_BACKUP_PV      = var.gitlab_enable_backup_pv
      BACKUP_PV_SIZE        = var.gitlab_backup_pv_size
      ENABLE_RESTORE_PV     = var.gitlab_enable_restore_pv
      RESTORE_PV_SIZE       = var.gitlab_restore_pv_size
      BACKUP_PV_SC          = var.gke_sc_gitlab_backup_disk
      RESTORE_PV_SC         = var.gke_sc_gitlab_restore_disk
      PV_MATCH_LABEL        = var.gke_gitaly_pv_labels
      ENABLE_MIGRATIONS     = var.gitab_enable_migrations
      ENABLE_PROM_EXPORTER  = var.gitab_enable_prom_exporter

      #Bucket Names
      ARTIFACTS_BCKT    = google_storage_bucket.gitlab_bucket["artifacts"].name
      BACKUP_BCKT       = google_storage_bucket.gitlab_bucket["backups"].name
      DEP_PROXY_BCKT    = google_storage_bucket.gitlab_bucket["dependency-proxy"].name
      EXT_DIFF_BCKT     = google_storage_bucket.gitlab_bucket["external-diffs"].name
      LFS_BCKT          = google_storage_bucket.gitlab_bucket["git-lfs"].name
      PACKAGES_BCKT     = google_storage_bucket.gitlab_bucket["packages"].name
      REGISTRY_BCKT     = google_storage_bucket.gitlab_bucket["registry"].name
      RUNNER_CACHE_BCKT = google_storage_bucket.gitlab_bucket["runner-cache"].name
      TERRAFORM_BCKT    = google_storage_bucket.gitlab_bucket["terraform-state"].name
      BACKUP_TMP_BCKT   = google_storage_bucket.gitlab_bucket["tmp-backups"].name
      UPLOADS_BCKT      = google_storage_bucket.gitlab_bucket["uploads"].name

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
      MONITORING_ALLOWED_CIDRS    = local.monitoring_allowed_cidrs
    }
  )
}

resource "time_sleep" "sleep_for_cluster_fix_helm_6361" {
  create_duration  = "180s"
  destroy_duration = "180s"
  depends_on       = [module.gke.endpoint, google_sql_database.gitlabhq_production]
}

resource "helm_release" "gitlab" {
  name       = "gitlab"
  namespace  = var.gitlab_namespace
  repository = "https://charts.gitlab.io"
  chart      = "gitlab"
  version    = var.helm_chart_version
  timeout    = 600

  values = [local.gitlab_release_helm_values]

  depends_on = [
    google_redis_instance.gitlab,
    google_sql_user.gitlab,
    kubernetes_namespace.gitlab_namespace,
    kubernetes_storage_class.storage_class,
    kubernetes_secret.gitlab_rails_storage,
    kubernetes_secret.gitlab_registry_storage,
    kubernetes_secret.gitlab_gcs_credentials,
    kubernetes_secret.postgresql_mtls_secret,
    time_sleep.sleep_for_cluster_fix_helm_6361,
    module.cloud_nat,
    module.gitlab_db_pass,
  ]
}
