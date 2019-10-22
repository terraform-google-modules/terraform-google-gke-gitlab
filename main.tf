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

provider "google" {
  project = "${var.project_id}"
}

provider "google-beta" {
  project = "${var.project_id}"
}

provider "helm" {
  service_account = "tiller"
  install_tiller  = true
  namespace       = "kube-system"

  kubernetes {
    insecure               = true
    host                   = "${google_container_cluster.gitlab.endpoint}"
    client_certificate     = "${base64decode(google_container_cluster.gitlab.master_auth.0.client_certificate)}"
    client_key             = "${base64decode(google_container_cluster.gitlab.master_auth.0.client_key)}"
//    cluster_ca_certificate = "${base64decode(google_container_cluster.gitlab.master_auth.0.cluster_ca_certificate)}"
  }
}

provider "kubernetes" {
  insecure               = true
  load_config_file       = false
  host                   = "${google_container_cluster.gitlab.endpoint}"
  client_certificate     = "${base64decode(google_container_cluster.gitlab.master_auth.0.client_certificate)}"
  client_key             = "${base64decode(google_container_cluster.gitlab.master_auth.0.client_key)}"
//  cluster_ca_certificate = "${base64decode(google_container_cluster.gitlab.master_auth.0.cluster_ca_certificate)}"
}

// IAM
resource "google_project_service" "compute" {
  project            = "${var.project_id}"
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "gke" {
  project            = "${var.project_id}"
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "service_networking" {
  project            = "${var.project_id}"
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager" {
  project            = "${var.project_id}"
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}