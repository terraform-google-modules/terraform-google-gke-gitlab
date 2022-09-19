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
}

output "secret_id" {
  description = "Id of secret"
  value       = local.secret_id
}

output "secret_value" {
  description = "Secret Payload"
  value       = local.secret_value
  sensitive   = true
}
