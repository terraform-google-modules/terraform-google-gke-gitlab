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

######################
#  GENERAL SECTION   #
######################

variable "project_id" {
  description = "GCP Project to deploy resources"
}

variable "region" {
  default     = "europe-west1"
  description = "GCP region to deploy resources to"
}

variable "allow_force_destroy" {
  type        = bool
  default     = false
  description = "Allows full cleanup of resources by disabling any deletion safe guards"
}

variable "gitlab_address_name" {
  description = "Name of the address to use for GitLab ingress"
  default     = ""
}

##########################
#  POSTGRES DB SECTION   #
##########################

variable "postgresql_version" {
  description = "(Required) The PostgreSQL version to use. Supported values for Gitlab POSTGRES_12, POSTGRES_13. Default: POSTGRES_12"
  default     = "POSTGRES_12"
}

variable "postgresql_tier" {
  description = "(Required) The machine type to use.Postgres supports only shared-core machine types, and custom machine types such as db-custom-2-13312"
  default     = "db-custom-2-8192"
}

variable "gitlab_db_name" {
  description = "Instance name for the GitLab Postgres database."
  default     = "gitlab-db"
}

variable "gitlab_db_random_prefix" {
  description = "Sets random suffix at the end of the Cloud SQL instance name."
  default     = false
}

#######################
#    REDIS SECTION    #
#######################

variable "redis_tier" {
  description = "The service tier of the instance. Must be one of these values BASIC and STANDARD_HA"
  default     = "STANDARD_HA"
}

variable "redis_size" {
  description = "Redis memory size in GiB."
  default     = "1"
}

##################
#  GKE SECTION   #
##################

variable "gke_version" {
  description = "Version of GKE to use for the GitLab cluster"
  default     = "1.20"
}

variable "gke_machine_type" {
  description = "Machine type used for the node-pool"
  default     = "n1-standard-4"
}

variable "gitlab_nodes_subnet_cidr" {
  default     = "10.0.0.0/16"
  description = "Cidr range to use for gitlab GKE nodes subnet"
}

variable "gitlab_pods_subnet_cidr" {
  default     = "10.3.0.0/16"
  description = "Cidr range to use for gitlab GKE pods subnet"
}

variable "gitlab_services_subnet_cidr" {
  default     = "10.2.0.0/16"
  description = "Cidr range to use for gitlab GKE services subnet"
}

##################
# GITLAB SECTION #
##################

# Gitlab Version Helm CHart

variable "helm_chart_version" {
  type        = string
  default     = "5.9.3"
  description = "Helm chart version to install during deployment - Default Gitlab 4.9.3"
}

variable "domain" {
  description = "Domain for hosting gitlab functionality (ie mydomain.com would access gitlab at gitlab.mydomain.com)"
  default     = ""
}

variable "gitlab_db_password" {
  description = "Password for the GitLab Postgres user"
  default     = ""
}

variable "certmanager_email" {
  description = "Email used to retrieve SSL certificates from Let's Encrypt"
}

variable "gitlab_runner_install" {
  description = "Choose whether to install the gitlab runner in the cluster"
  default     = true
}

variable "gitlab_install_prometheus" {
  type        = bool
  description = "Choose whether to install a Prometheus instance using the Gitlab chart. Default to false."
  default     = false
}

variable "gitlab_install_grafana" {
  type        = bool
  description = "Choose whether to install a Grafana instance using the Gitlab chart. Default to false."
  default     = false
}

variable "gitlab_install_ingress_nginx" {
  type        = bool
  description = "Choose whether to install the ingress nginx controller in the cluster. Default to true."
  default     = true
}

# Peformance optimization. Max and min pod replicas for HPA.
variable "gitlab_hpa_min_replicas_registry" {
  type        = number
  description = "Set the minimum hpa pod replicas for the Gitlab Registry."
  default     = 2
}

variable "gitlab_hpa_min_replicas_shell" {
  type        = number
  description = "Set the minimum hpa pod replicas for the Gitlab Shell."
  default     = 2
}

variable "gitlab_hpa_min_replicas_kas" {
  type        = number
  description = "Set the minimum hpa pod replicas for the Gitlab Kas."
  default     = 2
}

variable "gitlab_hpa_min_replicas_sidekiq" {
  type        = number
  description = "Set the minimum hpa pod replicas for the Gitlab sidekiq."
  default     = 1
}

variable "gitlab_hpa_min_replicas_webservice" {
  type        = number
  description = "Set the minimum hpa pod replicas for the Gitlab webservice."
  default     = 2
}

variable "gitlab_hpa_max_replicas_registry" {
  type        = number
  description = "Set the maximum hpa pod replicas for the Gitlab Registry."
  default     = 10
}

variable "gitlab_hpa_max_replicas_shell" {
  type        = number
  description = "Set the maximum hpa pod replicas for the Gitlab Shell."
  default     = 10
}

variable "gitlab_hpa_max_replicas_kas" {
  type        = number
  description = "Set the maximum hpa pod replicas for the Gitlab Kas."
  default     = 10
}

variable "gitlab_hpa_max_replicas_sidekiq" {
  type        = number
  description = "Set the maximum hpa pod replicas for the Gitlab sidekiq."
  default     = 10
}

variable "gitlab_hpa_max_replicas_webservice" {
  type        = number
  description = "Set the maximum hpa pod replicas for the Gitlab webservice."
  default     = 10
}
