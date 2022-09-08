resource "google_secret_manager_secret" "secret" {
  project     = var.project
  secret_id   = var.secret_id
  labels      = var.labels
  expire_time = var.expire_time

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "secret" {
  secret      = google_secret_manager_secret.secret.id
  secret_data = var.secret_data
}