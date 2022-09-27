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
  type        = string
  description = "GCP Project to deploy resources"
}

variable "region" {
  type        = string
  description = "GCP region to deploy resources to"
  default     = "europe-west1"
}

variable "allow_force_destroy" {
  type        = bool
  default     = false
  description = "Allows full cleanup of resources by disabling any deletion safe guards"
}

variable "gitlab_address_name" {
  type        = string
  description = "Name of the address to use for GitLab ingress"
  default     = ""
}

##########################
#  POSTGRES DB SECTION   #
##########################

variable "postgresql_version" {
  type        = string
  description = "(Required) The PostgreSQL version to use. Supported values for Gitlab POSTGRES_12, POSTGRES_13. Default: POSTGRES_12"
  default     = "POSTGRES_12"
}

variable "postgresql_tier" {
  type        = string
  description = "(Required) The machine type to use.Postgres supports only shared-core machine types, and custom machine types such as db-custom-2-13312"
  default     = "db-custom-2-8192"
}

variable "postgresql_disk_size" {
  type        = number
  description = "he size of data disk, in GB. Size of a running instance cannot be reduced but can be increased. Default to 100 GB"
  default     = "100"
}

variable "postgresql_disk_type" {
  type        = string
  description = "The type of postgresql data disk: PD_SSD or PD_HDD. "
  default     = "PD_SSD"
}

variable "postgresql_availability_type" {
  type        = string
  description = "The availability type of the Cloud SQL instance, high availability (REGIONAL) or single zone (ZONAL)."
  default     = "REGIONAL"
}

variable "postgresql_del_protection" {
  type        = bool
  description = "Whether or not to allow Terraform to destroy the instance. Unless this field is set to false in Terraform state, a terraform destroy or terraform apply command that deletes the instance will fail."
  default     = true
}

variable "postgresql_enable_backup" {
  type        = bool
  description = "Setup if postgres backup configuration is enabled.Default true"
  default     = true
}

variable "postgresql_backup_start_time" {
  type        = string
  description = "HH:MM format time indicating when postgres backup configuration starts."
  default     = "02:00"
}

variable "postgresql_backup_retained_count" {
  type        = number
  description = "Numeber of postgres backup to be retained. Default 30."
  default     = "30"
}

variable "postgresql_db_random_suffix" {
  type        = bool
  description = "Sets random suffix at the end of the Cloud SQL instance name."
  default     = false
}

####################
#  REDIS SECTION   #
####################

variable "redis_tier" {
  type        = string
  description = "The service tier of the instance. Must be one of these values BASIC and STANDARD_HA"
  default     = "STANDARD_HA"
}

variable "redis_size" {
  type        = number
  description = "Redis memory size in GiB."
  default     = 1
}

##################
#  GCS SECTION   #
##################

variable "gcs_bucket_random_suffix" {
  type        = bool
  description = "Sets random suffix at the end of the bucket name."
  default     = false
}

variable "gcs_bucket_storage_class" {
  type        = string
  description = "Bucket storage class. Supported values include: STANDARD, MULTI_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE "
  default     = "STANDARD"
}

##################
#  GKE SECTION   #
##################

variable "gke_min_node_count" {
  type        = number
  description = "Define the minimum number of nodes of the autoscaling cluster. Default 1"
  default     = 1
}

variable "gke_max_node_count" {
  type        = number
  description = "Define the maximum number of nodes of the autoscaling cluster. Default 5"
  default     = 5
}

variable "gke_machine_type" {
  type        = string
  description = "Machine type used for the node-pool"
  default     = "n1-standard-4"
}

variable "gke_storage_class" {
  type        = string
  description = "Default storage class for GKE Cluster. Default pd-sdd."
  default     = "pd-ssd"
}

variable "gke_disk_replication" {
  type        = string
  description = "Setup replication type for disk persistent volune. Possible values none or regional-pd. Default to none."
  default     = "none"
}

variable "gke_version" {
  type        = string
  description = "Version of GKE to use for the GitLab cluster"
  default     = "latest"
}

variable "gke_nodes_subnet_cidr" {
  type        = string
  default     = "10.10.0.0/16"
  description = "Cidr range to use for gitlab GKE nodes subnet"
}

variable "gke_pods_subnet_cidr" {
  type        = string
  default     = "10.30.0.0/16"
  description = "Cidr range to use for gitlab GKE pods subnet"
}

variable "gke_services_subnet_cidr" {
  type        = string
  default     = "10.20.0.0/16"
  description = "Cidr range to use for gitlab GKE services subnet"
}

variable "gke_enable_cloudrun" {
  type        = bool
  description = "Enable Google Cloudrun on GKE Cluster. Default false"
  default     = false
}

variable "gke_datapath" {
  type        = string
  description = "The desired datapath provider for this cluster. By default, DATAPATH_PROVIDER_UNSPECIFIED enables the IPTables-based kube-proxy implementation. ADVANCED_DATAPATH enables Dataplane-V2 feature."
  default     = "DATAPATH_PROVIDER_UNSPECIFIED"
}

variable "gke_google_group_rbac_mail" {
  type        = string
  description = "The name of the RBAC security group for use with Google security groups in Kubernetes RBAC. Group name must be in format gke-security-groups@yourdomain.com"
  default     = "null"
}

variable "gke_enable_image_stream" {
  type        = bool
  description = "Google Container File System (gcfs) has to be enabled for image streaming to be active. Needs image_type to be set to COS_CONTAINERD."
  default     = false
}

variable "gke_enable_backup_agent" {
  type        = bool
  description = "Whether Backup for GKE agent is enabled for this cluster."
  default     = false
}

variable "gke_enable_istio_addon" {
  type        = bool
  description = "Enable Istio addon"
  default     = false
}

variable "gke_istio_auth" {
  type        = string
  description = "The authentication type between services in Istio"
  default     = "AUTH_MUTUAL_TLS"
}

variable "gke_sc_gitlab_backup_disk" {
  type        = string
  description = "Storage class for Perstistent Volume used for extra space in Backup Cron Job . Default pd-sdd."
  default     = "pd-ssd"
}

variable "gke_sc_gitlab_restore_disk" {
  type        = string
  description = "Storage class for Perstistent Volume used for extra space in Backup Restore Job. Default pd-sdd."
  default     = "pd-ssd"
}

variable "gke_cluster_resource_labels" {
  type        = map(string)
  description = "The GCE resource labels (a map of key/value pairs) to be applied to the cluster"
  default     = {}
}

##################
# GITLAB SECTION #
##################

# Gitlab Version Helm CHart

variable "helm_chart_version" {
  type        = string
  default     = "5.9.3"
  description = "Helm chart version to install during deployment - Default Gitlab 14.9.3"
}

variable "domain" {
  type        = string
  description = "Domain for hosting gitlab functionality (ie mydomain.com would access gitlab at gitlab.mydomain.com)"
  default     = ""
}

variable "gitlab_db_name" {
  type        = string
  description = "Instance name for the GitLab Postgres database."
  default     = "gitlab-db"
}

variable "gcp_existing_db_secret_name" {
  type        = string
  description = "Setup the GCP secret name where to retrieve the password value that will be used for postgres DB. In case an empty string is passed,a random value will be filled in a default gcp secret named gitlab-db-password"
  default     = ""
}


variable "gcp_existing_smtp_secret_name" {
  type        = string
  description = "Only if STMP is enabled. Setup the GCP secret name where to retrieve the password value that will be used for Smtp Account."
  default     = ""
}

variable "gcp_existing_omniauth_secret_name" {
  type        = string
  description = "Only if Omniauth is enabled. Setup the GCP secret name where to retrieve the configuration that will be used for Omniauth Configuration."
  default     = ""
}

variable "certmanager_email" {
  type        = string
  description = "Email used to retrieve SSL certificates from Let's Encrypt"
}

variable "gitlab_install_runner" {
  type        = string
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

variable "gitlab_install_kas" {
  type        = bool
  description = "Choose whether to install the Gitlab agent server in the cluster. Default to false."
  default     = false
}

variable "gitlab_enable_certmanager" {
  type        = bool
  description = "Choose whether to Install certmanager through Gitlab Helm Chart. Default to true."
  default     = true
}

variable "gitlab_enable_smtp" {
  type        = bool
  description = "Setup Gitlab email address to send email."
  default     = false
}

variable "gitlab_smtp_user" {
  type        = string
  description = "Setup email sender address for Gitlab smtp server to send emails."
  default     = "user@example.com"
}

variable "gitlab_time_zone" {
  type        = string
  description = "Setup timezone for gitlab containers"
  default     = "Europe/Rome"
}

variable "gitlab_namespace" {
  type        = string
  description = "Setup  the Kubernetes Namespace where to install gitlab"
  default     = "gitlab"
}

variable "gitlab_backup_extra_args" {
  type        = string
  description = "Add a string of extra arguments for the gitlab backup-utility."
  default     = ""
}

variable "gitlab_enable_registry" {
  type        = bool
  description = "Choose whether to enable Gitlab Container registry. Default to false."
  default     = false
}

variable "gitlab_enable_cron_backup" {
  type        = bool
  description = "Choose whether to enable Gitlab Scheduled Backups. Default to true."
  default     = true
}

variable "gitlab_schedule_cron_backup" {
  type        = string
  description = "Setup Cron Job for Gitlab Scheduled Backup using unix-cron string format. Default to '0 1 * * *' (Everyday at 1 AM)."
  default     = "0 1 * * *"
}

variable "gitlab_gitaly_disk_size" {
  type        = number
  description = "Setup persistent disk size for gitaly data in GB. Default 200 GB"
  default     = 100
}

variable "gitlab_enable_omniauth" {
  type        = bool
  description = "Choose whether to enable Gitlab Omniauth integration. Default to false."
  default     = false
}

variable "gitlab_enable_backup_pv" {
  type        = bool
  description = "Enable additional storage for TAR backup creation of any appreciable size"
  default     = false
}

variable "gitlab_backup_pv_size" {
  type        = number
  description = "Set the size of the additional storage for Backup TAR Creation"
  default     = 100
}

variable "gitlab_enable_restore_pv" {
  type        = bool
  description = "Enable additional storage for TAR Restoration creation of any appreciable size"
  default     = false
}

variable "gitlab_restore_pv_size" {
  type        = number
  description = "Set the size of the additional storage for Backup TAR Restoration Process"
  default     = 100
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

######################
# MONITORING SECTION #
######################

variable "uptime_monitoring_path" {
  type        = string
  description = "The path to the page to run the check against."
  default     = "/-/liveness"
}

variable "notification_channels" {
  type        = list(string)
  description = "Identifies the notification channels to which notifications should be sent when incidents are opened or closed. The syntax of the entries in this field is projects/[PROJECT_ID]/notificationChannels/[CHANNEL_ID]"
  default     = [""]
}
