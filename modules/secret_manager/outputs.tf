output "secret" {
  description = "Secret resource"
  value       = google_secret_manager_secret.secret
}

output "project" {
  description = "Project containing secret"
  value       = var.project
}

output "region" {
  description = "Region containing secret"
  value       = var.region

  depends_on = [
    google_secret_manager_secret_version.secret,
  ]
}

output "secret_id" {
  description = "Id of secret"
  value       = var.secret_id

  depends_on = [
    google_secret_manager_secret_version.secret,
  ]
}

output "secret_payload" {
  description = "Secret Payload"
  value       = var.secret_data
  sensitive   = true

  depends_on = [
    google_secret_manager_secret_version.secret,
  ]
}

