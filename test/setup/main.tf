/**
 * Copyright 2020 Google LLC
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

module "gke-gitlab-proj" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  name                        = "ci-gitlab"
  random_project_id           = true
  org_id                      = var.org_id
  folder_id                   = var.folder_id
  billing_account             = var.billing_account
  disable_services_on_destroy = false

  auto_create_network = true

  activate_apis = [
    "iam.googleapis.com",
    "serviceusage.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "sqladmin.googleapis.com",
  ]
}
