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
  type        = string
}

variable "domain" {
  description = "Domain for hosting gitlab functionality (ie mydomain.com would access gitlab at gitlab.mydomain.com)"
  type        = string
  default     = ""
}

variable "certmanager_email" {
  description = "Email used to retrieve SSL certificates from Let's Encrypt"
  type        = string
}

variable "gke_version" {
  description = "Version of GKE to use for the GitLab cluster"
  type        = string
  default     = "1.28"
}

variable "gke_machine_type" {
  description = "Machine type used for the node-pool"
  type        = string
  default     = "n1-standard-4"
}

variable "gitlab_db_name" {
  description = "Instance name for the GitLab Postgres database."
  type        = string
  default     = "gitlab-db"
}

variable "gitlab_db_random_prefix" {
  description = "Sets random suffix at the end of the Cloud SQL instance name."
  type        = bool
  default     = false
}

variable "gitlab_deletion_protection" {
  description = "Must be false to allow Terraform to destroy the Cloud SQL instance."
  type        = bool
  default     = true
}

variable "gitlab_db_password" {
  description = "Password for the GitLab Postgres user"
  type        = string
  default     = ""
}

variable "gitlab_address_name" {
  description = "Name of the address to use for GitLab ingress"
  type        = string
  default     = ""
}

variable "gitlab_runner_install" {
  description = "Choose whether to install the gitlab runner in the cluster"
  type        = bool
  default     = true
}

variable "region" {
  default     = "us-central1"
  type        = string
  description = "GCP region to deploy resources to"
}

variable "gitlab_nodes_subnet_cidr" {
  default     = "10.0.0.0/16"
  type        = string
  description = "Cidr range to use for gitlab GKE nodes subnet"
}

variable "gitlab_pods_subnet_cidr" {
  default     = "10.3.0.0/16"
  type        = string
  description = "Cidr range to use for gitlab GKE pods subnet"
}

variable "gitlab_services_subnet_cidr" {
  default     = "10.2.0.0/16"
  type        = string
  description = "Cidr range to use for gitlab GKE services subnet"
}

variable "helm_chart_version" {
  type        = string
  default     = "4.2.4"
  description = "Helm chart version to install during deployment"
}

variable "allow_force_destroy" {
  type        = bool
  default     = false
  description = "Allows full cleanup of resources by disabling any deletion safe guards"
}
