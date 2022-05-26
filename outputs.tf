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

output "root_password_instructions" {
  value = <<EOF

  Run the following commands to get the root user password:

  gcloud container clusters get-credentials gitlab --zone ${var.region} --project ${var.project_id}
  kubectl get secret gitlab-gitlab-initial-root-password -o go-template='{{ .data.password }}' | base64 -d && echo
  EOF

  description = "Instructions for getting the root user's password for initial setup"
}
