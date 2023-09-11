resource "random_password" "random_pass" {
  length  = 16
  special = false

  count = var.secret_id == "" ? 1 : 0
}

resource "random_id" "gcp_secret_suffix" {
  byte_length = 4

  count = var.secret_id == "" ? 1 : 0
}

locals {
  secret_id    = var.secret_id == "" ? "${var.project}-gitlab-secret-${random_id.gcp_secret_suffix[0].hex}" : var.secret_id
  secret_value = var.secret_id == "" ? random_password.random_pass[0].result : data.google_secret_manager_secret_version.gcp_predefined_pass[0].secret_data
}

# Recover the GCP secret payload when GCP secret name is provided
data "google_secret_manager_secret_version" "gcp_predefined_pass" {
  secret  = local.secret_id
  project = var.project

  count = var.secret_id != "" ? 1 : 0
}

# GCP Secret Manager
resource "google_secret_manager_secret" "secret" {
  project     = var.project
  secret_id   = local.secret_id
  labels      = var.secret_labels
  expire_time = var.secret_expire_time

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
  count = var.secret_id == "" ? 1 : 0
}

# GCP Secret Manager Payload
resource "google_secret_manager_secret_version" "secret" {
  secret      = google_secret_manager_secret.secret[0].id
  secret_data = local.secret_value

  count = var.secret_id == "" ? 1 : 0
}

# Kubernetes Secret
resource "kubernetes_secret" "k8s_secret" {
  metadata {
    name      = var.k8s_secret_name
    namespace = var.k8s_namespace
  }
  data = {
    (var.k8s_secret_key) = (local.secret_value)
  }
  count = var.k8s_create_secret ? 1 : 0
}
