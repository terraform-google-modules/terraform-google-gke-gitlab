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
  description = "Domain for hosting gitlab functionality (ie mydomain.com would access gitlab at `gitlab.mydomain.com` and the registry at `registry.mydomain.com`)"
  default     = ""
}

variable "certmanager_email" {
  description = "Email used to retrieve SSL certificates from [Let's Encrypt](https://letsencrypt.org)"
}

variable "gke_release_channel" {
  description = "Kubernetes releases updates often, to deliver security updates, fix known issues, and introduce new features. [Release channels](https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels) offer customers the ability to balance between stability and the feature set of the version deployed in the cluster."
  default     = "REGULAR"
}

variable "gke_machine_type" {
  description = "[Machine type](https://cloud.google.com/compute/docs/machine-types) used for the node-pool"
  default     = "n1-standard-4"
}

variable "gke_preemptible_nodes" {
  description = "[Preemptible VMs](https://cloud.google.com/compute/docs/instances/preemptible) are instances that you can create and run at a much lower price than normal instances. However, Compute Engine might stop (preempt) these instances if it requires access to those resources for other tasks. They're suitable for a GKE development deployment."
  default     = false
}

variable "gke_min_node_count" {
  description = "Mininum GKE nodes per availability zone"
  default     = 1
}

variable "gke_max_node_count" {
  description = "Maximum GKE nodes per availability zone"
  default     = 2
}

variable "gitlab_db_name" {
  description = "Instance name for the GitLab Postgres database."
  default     = "gitlab-db"
}

variable "gitlab_db_random_prefix" {
  description = "Sets random suffix at the end of the Cloud SQL instance name."
  default     = false
}

variable "gitlab_db_password" {
  description = "Password for the GitLab Postgres user"
  default     = ""
}

variable "gitlab_address_name" {
  description = "Name of the address to use for GitLab ingress"
  default     = ""
}

variable "gitlab_runner_install" {
  description = "Choose whether to install the gitlab runner in the cluster"
  default     = true
}

variable "region" {
  default     = "us-central1"
  description = "GCP region to deploy resources to"
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

variable "helm_chart_version" {
  type        = string
  default     = "5.0.3"
  description = "Helm chart version to install during deployment ([GitLab version mapping](https://docs.gitlab.com/charts/installation/version_mappings.html))"
}

variable "allow_force_destroy" {
  type        = bool
  default     = false
  description = "Allows full cleanup of resources by disabling any deletion safe guards"
}
