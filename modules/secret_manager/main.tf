resource "random_password" "random_pass" {
  length  = 16
  special = false
}

# Recover the GCP secret payload when GCP secret name is provided
data "google_secret_manager_secret_version" "gcp_predefined_pass" {
  secret    = var.secret_value
  project   = var.project
}

locals {
   secret_value = var.secret_value == "" ? random_password.random_pass.result : data.google_secret_manager_secret_version.gcp_predefined_pass.secret_data
}

# GCP Secret Manager
resource "google_secret_manager_secret" "secret" {
  project     = var.project
  secret_id   = var.secret_id
  labels      = var.secret_labels
  expire_time = var.secret_expire_time

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
  count = var.secret_value == "" ? 1 : 0
}

# GCP Secret Manager Payload
resource "google_secret_manager_secret_version" "secret" {
  secret      = google_secret_manager_secret.secret[0].id
  secret_data = local.secret_value
}

# Kubernetes Secret
resource "kubernetes_secret" "k8s_secret" {
  metadata {
    name      = var.k8s_secret_name
    namespace = var.k8s_namespace
  }
  data  = {
    (var.k8s_secret_key) = (local.secret_value)
  }
  count = var.k8s_create_secret ? 1 : 0
}