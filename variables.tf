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

variable "project_id" {
  description = "GCP Project to deploy resources"
}

variable "domain" {
  description = "Domain for hosting gitlab functionality (ie mydomain.com would access gitlab at gitlab.mydomain.com)"
  default     = ""
}

variable "certmanager_email" {
  description = "Email used to retrieve SSL certificates from Let's Encrypt"
}

variable "gitlab_db_password" {
  description = "Password for the GitLab Postgres user"
  default     = ""
}

variable "gitlab_runner_install" {
  description = "Choose whether to install the gitlab runner in the cluster"
  default     = true
}

variable "gitlab_edition" {
  description = "Edition of Gitlab. Allowed values: ce, ee"
  default     = "ce"
}

variable "region" {
  default     = "us-central1"
  description = "GCP region to deploy resources to"
}

variable "redis_tier" {
  default     = "STANDARD_HA"
  description = "Service tier of instance. One of BASIC (standalone) or STANDARD_HA (ha)"
}

variable "redis_size_gb" {
  default     = 5
  description = "Size of Cloud Memorystore for Redis"
}

variable "gke_default_pool_nodes_type" {
  default     = "n1-standard-4"
  description = "Type of GKE worker node"
}

variable "gke_min_version" {
  default     = "1.13"
  description = "Minimal Kubernetes version on GKE"
}

variable "gke_enable_abac" {
  default     = false
  description = "Insecure! Flag if deprecated ABAC authorization should be enabled."
}

variable "cloud_sql_version" {
  default     = "POSTGRES_9_6"
  description = "Version of Cloud SQL. It must be supported by Gitlab"
}

variable "cloud_sql_tier" {
  default     = "db-custom-4-15360"
  description = "Tier (size) of Cloud SQL."
}

variable "cloud_sql_availability_type" {
  default     = "REGIONAL"
  description = "Cloud SQL availability type. One of REGIONAL (ha) or ZONAL (single zone)"
}

variable "gitlab_chart_version" {
  default     = "2.3.7"
  description = "Version of Gitlab Helm Chart"
}

variable "network_cidr" {
  default     = "10.0.0.0/16"
  description = "Kubernetes network CIDR"
}

variable "omniauth" {
  description = <<EOF

  enabled: Should the omniauth configuration be enabled in Gitlab or not.
  sso_providers: A list of single sign on providers to enable.
  sso_profile_providers: List of provider names that GitLab should automatically sync profile information from.
  sso_profile_attributes: List of profile attributes to sync from the provider upon login.
  google_client_id: The client ID to use for Google OAuth2.
  google_client_secret: The client secret to use for Google OAuth2.

  EOF

  type = object({
    enabled                 = bool
    sso_providers           = list(string)
    sync_profile_providers  = list(string)
    sync_profile_attributes = list(string)
    google_client_id        = string
    google_client_secret    = string
  })

  default = {
    enabled                 = false
    sso_providers           = []
    sync_profile_providers  = []
    sync_profile_attributes = ["email"]
    google_client_id        = ""
    google_client_secret    = ""
  }
}
