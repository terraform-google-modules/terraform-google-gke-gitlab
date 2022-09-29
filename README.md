# terraform-sparkfabrik-gke-gitlab

This module creates a reslient and fault tolerant GitLab installation using Google
Kubernetes Engine (GKE) as the computing environment and the following services for storing
data:
- CloudSQL for PostgreSQL
- Memorystore for Redis
- Cloud Storage

![GitLab on GKE architecture diagram](img/arch.png)

## Usage
There are examples included in the [examples](./examples/) folder but simple usage is as follows:

```hcl
module "gke-gitlab" {
  source                     = "terraform-google-modules/gke-gitlab/google"
  project_id                 = "<PROJECT ID>"
  certmanager_email          = "test@example.com"
}
```

Then perform the following commands on the root folder:

- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build
- `terraform destroy` to destroy the built infrastructure


 <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| certmanager\_email | Email used to retrieve SSL certificates from Let's Encrypt | `string` | n/a | yes |
| domain | Domain for hosting gitlab functionality (ie mydomain.com would access gitlab at gitlab.mydomain.com) | `string` | `""` | no |
| gcp\_existing\_db\_secret\_name | Setup the GCP secret name where to retrieve the password value that will be used for postgres DB. In case an empty string is passed,a random value will be filled in a default gcp secret named gitlab-db-password | `string` | `""` | no |
| gcp\_existing\_omniauth\_secret\_name | Only if Omniauth is enabled. Setup the GCP secret name where to retrieve the configuration that will be used for Omniauth Configuration. | `string` | `""` | no |
| gcp\_existing\_smtp\_secret\_name | Only if STMP is enabled. Setup the GCP secret name where to retrieve the password value that will be used for Smtp Account. | `string` | `""` | no |
| gcs\_bucket\_age\_backup\_sc\_change | When the backup lifecycle is enabled, set the number of days after the storage class changes | `number` | `30` | no |
| gcs\_bucket\_allow\_force\_destroy | Allows full cleanup of buckets by disabling any deletion safe guards | `bool` | `false` | no |
| gcs\_bucket\_backup\_duration | When the backup lifecycle is enabled, set the number of days after which the backup files are deleted | `number` | `120` | no |
| gcs\_bucket\_enable\_backup\_lifecycle\_rule | Enable lifecycle rule for backup bucket | `bool` | `false` | no |
| gcs\_bucket\_storage\_class | Bucket storage class. Supported values include: STANDARD, MULTI\_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE | `string` | `"STANDARD"` | no |
| gcs\_bucket\_target\_storage\_class | The target Storage Class of objects affected by this Lifecycle Rule. Supported values include: STANDARD, MULTI\_REGIONAL, REGIONAL, NEARLINE, COLDLINE, ARCHIVE. | `string` | `"COLDLINE"` | no |
| gcs\_bucket\_versioning | Setup Object Storage versioning for all Bucket created. | `bool` | `true` | no |
| gitlab\_address\_name | Name of the address to use for GitLab ingress | `string` | `""` | no |
| gitlab\_backup\_extra\_args | Add a string of extra arguments for the gitlab backup-utility. | `string` | `""` | no |
| gitlab\_backup\_pv\_size | Set the size of the additional storage for Backup TAR Creation | `number` | `100` | no |
| gitlab\_db\_name | Instance name for the GitLab Postgres database. | `string` | `"gitlab-db"` | no |
| gitlab\_enable\_backup\_pv | Enable additional storage for TAR backup creation of any appreciable size | `bool` | `false` | no |
| gitlab\_enable\_certmanager | Choose whether to Install certmanager through Gitlab Helm Chart. Default to true. | `bool` | `true` | no |
| gitlab\_enable\_cron\_backup | Choose whether to enable Gitlab Scheduled Backups. Default to true. | `bool` | `true` | no |
| gitlab\_enable\_omniauth | Choose whether to enable Gitlab Omniauth integration. Default to false. | `bool` | `false` | no |
| gitlab\_enable\_registry | Choose whether to enable Gitlab Container registry. Default to false. | `bool` | `false` | no |
| gitlab\_enable\_restore\_pv | Enable additional storage for TAR Restoration creation of any appreciable size | `bool` | `false` | no |
| gitlab\_enable\_smtp | Setup Gitlab email address to send email. | `bool` | `false` | no |
| gitlab\_gitaly\_disk\_size | Setup persistent disk size for gitaly data in GB. Default 200 GB | `number` | `100` | no |
| gitlab\_hpa\_max\_replicas\_kas | Set the maximum hpa pod replicas for the Gitlab Kas. | `number` | `10` | no |
| gitlab\_hpa\_max\_replicas\_registry | Set the maximum hpa pod replicas for the Gitlab Registry. | `number` | `10` | no |
| gitlab\_hpa\_max\_replicas\_shell | Set the maximum hpa pod replicas for the Gitlab Shell. | `number` | `10` | no |
| gitlab\_hpa\_max\_replicas\_sidekiq | Set the maximum hpa pod replicas for the Gitlab sidekiq. | `number` | `10` | no |
| gitlab\_hpa\_max\_replicas\_webservice | Set the maximum hpa pod replicas for the Gitlab webservice. | `number` | `10` | no |
| gitlab\_hpa\_min\_replicas\_kas | Set the minimum hpa pod replicas for the Gitlab Kas. | `number` | `2` | no |
| gitlab\_hpa\_min\_replicas\_registry | Set the minimum hpa pod replicas for the Gitlab Registry. | `number` | `2` | no |
| gitlab\_hpa\_min\_replicas\_shell | Set the minimum hpa pod replicas for the Gitlab Shell. | `number` | `2` | no |
| gitlab\_hpa\_min\_replicas\_sidekiq | Set the minimum hpa pod replicas for the Gitlab sidekiq. | `number` | `1` | no |
| gitlab\_hpa\_min\_replicas\_webservice | Set the minimum hpa pod replicas for the Gitlab webservice. | `number` | `2` | no |
| gitlab\_install\_grafana | Choose whether to install a Grafana instance using the Gitlab chart. Default to false. | `bool` | `false` | no |
| gitlab\_install\_ingress\_nginx | Choose whether to install the ingress nginx controller in the cluster. Default to true. | `bool` | `true` | no |
| gitlab\_install\_kas | Choose whether to install the Gitlab agent server in the cluster. Default to false. | `bool` | `false` | no |
| gitlab\_install\_prometheus | Choose whether to install a Prometheus instance using the Gitlab chart. Default to false. | `bool` | `false` | no |
| gitlab\_install\_runner | Choose whether to install the gitlab runner in the cluster | `string` | `true` | no |
| gitlab\_namespace | Setup  the Kubernetes Namespace where to install gitlab | `string` | `"gitlab"` | no |
| gitlab\_restore\_pv\_size | Set the size of the additional storage for Backup TAR Restoration Process | `number` | `100` | no |
| gitlab\_schedule\_cron\_backup | Setup Cron Job for Gitlab Scheduled Backup using unix-cron string format. Default to '0 1 \* \* \*' (Everyday at 1 AM). | `string` | `"0 1 * * *"` | no |
| gitlab\_smtp\_user | Setup email sender address for Gitlab smtp server to send emails. | `string` | `"user@example.com"` | no |
| gitlab\_time\_zone | Setup timezone for gitlab containers | `string` | `"Europe/Rome"` | no |
| gke\_cluster\_resource\_labels | The GCE resource labels (a map of key/value pairs) to be applied to the cluster | `map(string)` | `{}` | no |
| gke\_datapath | The desired datapath provider for this cluster. By default, DATAPATH\_PROVIDER\_UNSPECIFIED enables the IPTables-based kube-proxy implementation. ADVANCED\_DATAPATH enables Dataplane-V2 feature. | `string` | `"DATAPATH_PROVIDER_UNSPECIFIED"` | no |
| gke\_disk\_replication | Setup replication type for disk persistent volune. Possible values none or regional-pd. Default to none. | `string` | `"none"` | no |
| gke\_enable\_backup\_agent | Whether Backup for GKE agent is enabled for this cluster. | `bool` | `false` | no |
| gke\_enable\_cloudrun | Enable Google Cloudrun on GKE Cluster. Default false | `bool` | `false` | no |
| gke\_enable\_image\_stream | Google Container File System (gcfs) has to be enabled for image streaming to be active. Needs image\_type to be set to COS\_CONTAINERD. | `bool` | `false` | no |
| gke\_enable\_istio\_addon | Enable Istio addon | `bool` | `false` | no |
| gke\_google\_group\_rbac\_mail | The name of the RBAC security group for use with Google security groups in Kubernetes RBAC. Group name must be in format gke-security-groups@yourdomain.com | `string` | `"null"` | no |
| gke\_istio\_auth | The authentication type between services in Istio | `string` | `"AUTH_MUTUAL_TLS"` | no |
| gke\_machine\_type | Machine type used for the node-pool | `string` | `"n1-standard-4"` | no |
| gke\_max\_node\_count | Define the maximum number of nodes of the autoscaling cluster. Default 5 | `number` | `5` | no |
| gke\_min\_node\_count | Define the minimum number of nodes of the autoscaling cluster. Default 1 | `number` | `1` | no |
| gke\_nodes\_subnet\_cidr | Cidr range to use for gitlab GKE nodes subnet | `string` | `"10.10.0.0/16"` | no |
| gke\_pods\_subnet\_cidr | Cidr range to use for gitlab GKE pods subnet | `string` | `"10.30.0.0/16"` | no |
| gke\_sc\_gitlab\_backup\_disk | Storage class for Perstistent Volume used for extra space in Backup Cron Job . Default pd-sdd. | `string` | `"standard"` | no |
| gke\_sc\_gitlab\_restore\_disk | Storage class for Perstistent Volume used for extra space in Backup Restore Job. Default pd-sdd. | `string` | `"standard"` | no |
| gke\_services\_subnet\_cidr | Cidr range to use for gitlab GKE services subnet | `string` | `"10.20.0.0/16"` | no |
| gke\_storage\_class | Default storage class for GKE Cluster. Default pd-sdd. | `string` | `"pd-ssd"` | no |
| gke\_version | Version of GKE to use for the GitLab cluster | `string` | `"latest"` | no |
| helm\_chart\_version | Helm chart version to install during deployment - Default Gitlab 14.9.3 | `string` | `"5.9.3"` | no |
| notification\_channels | Identifies the notification channels to which notifications should be sent when incidents are opened or closed. The syntax of the entries in this field is projects/[PROJECT\_ID]/notificationChannels/[CHANNEL\_ID] | `list(string)` | <pre>[<br>  ""<br>]</pre> | no |
| postgresql\_availability\_type | The availability type of the Cloud SQL instance, high availability (REGIONAL) or single zone (ZONAL). | `string` | `"REGIONAL"` | no |
| postgresql\_backup\_retained\_count | Numeber of postgres backup to be retained. Default 30. | `number` | `"30"` | no |
| postgresql\_backup\_start\_time | HH:MM format time indicating when postgres backup configuration starts. | `string` | `"02:00"` | no |
| postgresql\_db\_random\_suffix | Sets random suffix at the end of the Cloud SQL instance name. | `bool` | `false` | no |
| postgresql\_del\_protection | Whether or not to allow Terraform to destroy the instance. Unless this field is set to false in Terraform state, a terraform destroy or terraform apply command that deletes the instance will fail. | `bool` | `true` | no |
| postgresql\_disk\_size | he size of data disk, in GB. Size of a running instance cannot be reduced but can be increased. Default to 100 GB | `number` | `"100"` | no |
| postgresql\_disk\_type | The type of postgresql data disk: PD\_SSD or PD\_HDD. | `string` | `"PD_SSD"` | no |
| postgresql\_enable\_backup | Setup if postgres backup configuration is enabled.Default true | `bool` | `true` | no |
| postgresql\_tier | (Required) The machine type to use.Postgres supports only shared-core machine types, and custom machine types such as db-custom-2-13312 | `string` | `"db-custom-2-8192"` | no |
| postgresql\_version | (Required) The PostgreSQL version to use. Supported values for Gitlab POSTGRES\_12, POSTGRES\_13. Default: POSTGRES\_12 | `string` | `"POSTGRES_12"` | no |
| project\_id | GCP Project to deploy resources | `string` | n/a | yes |
| redis\_size | Redis memory size in GiB. | `number` | `1` | no |
| redis\_tier | The service tier of the instance. Must be one of these values BASIC and STANDARD\_HA | `string` | `"STANDARD_HA"` | no |
| region | GCP region to deploy resources to | `string` | `"europe-west1"` | no |
| uptime\_monitoring\_path | The path to the page to run the check against. | `string` | `"/-/liveness"` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster\_location | Location of the GKE cluster that GitLab is deployed in. |
| cluster\_name | Name of the GKE cluster that GitLab is deployed in. |
| gitlab\_address | IP address where you can connect to your GitLab instance |
| gitlab\_url | URL where you can access your GitLab instance |
| root\_password\_instructions | Instructions for getting the root user's password for initial setup |
| service\_account\_id | The id of the default service account |

 <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

Before this module can be used on a project, you must ensure that the following pre-requisites are fulfilled:

1. Terraform is [installed](#software-dependencies) on the machine where Terraform is executed.
2. The Service Account you execute the module with has the right [permissions](#configure-a-service-account).

The [project factory](https://github.com/terraform-google-modules/terraform-google-project-factory) can be used to provision projects with the correct APIs active.

### Software Dependencies
### Terraform
- [Terraform](https://www.terraform.io/downloads.html) 0.13.x
- [terraform-provider-google](https://github.com/terraform-providers/terraform-provider-google) plugin v1.8.0

### Configure a Service Account
In order to execute this module you must have a Service Account with the
following project roles:
- roles/owner

## Install

### Terraform
Be sure you have the correct Terraform version (0.13.x), you can choose the binary here:
- https://releases.hashicorp.com/terraform/

## File structure
The project has the following folders and files:

- /: root folder
- /examples: examples for using this module
- /helpers: Helper scripts
- /test: Folders with files for testing the module (see Testing section on this file)
- /main.tf: main file for this module, contains all the resources to create
- /variables.tf: all the variables for the module
- /output.tf: the outputs of the module
- /README.md: this file
