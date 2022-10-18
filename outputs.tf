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

output "gitlab_address" {
  value       = local.gitlab_address
  description = "IP address where you can connect to your GitLab instance"
}

output "gitlab_url" {
  value       = "https://gitlab.${local.domain}"
  description = "URL where you can access your GitLab instance"
}

output "cluster_name" {
  value       = module.gke.name
  description = "Name of the GKE cluster that GitLab is deployed in."
}

output "cluster_location" {
  value       = module.gke.location
  description = "Location of the GKE cluster that GitLab is deployed in."
}

output "cluster_endpoint" {
  sensitive   = true
  value       = module.gke.endpoint
  description = "Endpoint of the GKE cluster API server that GitLab is deployed in."
}

output "cluster_ca_certificate" {
  sensitive   = true
  value       = module.gke.ca_certificate
  description = "Certification Authority of the GKE cluster API server that GitLab is deployed in."
}

output "root_password_instructions" {
  value = <<EOF

  Run the following commands to get the root user password:

  gcloud container clusters get-credentials gitlab --zone ${var.region} --project ${var.project_id}
  kubectl get secret gitlab-gitlab-initial-root-password -o go-template='{{ .data.password }}' | base64 -d && echo
  EOF

  description = "Instructions for getting the root user's password for initial setup"
}

output "service_account_id" {
  value       = google_service_account.gitlab_gcs.account_id
  description = "The id of the default service account"
}

output "created_bucket_names" {
  value       = [for bucket in google_storage_bucket.gitlab_bucket : bucket.name]
  description = "The list of the created buckets."
}

output "buckets_random_suffix" {
  value       = random_string.random_suffix.result
  description = "The random suffix used to have unique bucket names."
}
