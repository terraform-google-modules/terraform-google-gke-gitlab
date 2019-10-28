resource "kubernetes_secret" "gitlab_pg" {
  metadata {
    name = "gitlab-pg"
  }

  data = {
    password = "${var.gitlab_db_password != "" ? var.gitlab_db_password : random_string.autogenerated_gitlab_db_password.result}"
  }
}

resource "kubernetes_secret" "gitlab_rails_storage" {
  metadata {
    name = "gitlab-rails-storage"
  }

  data = {
    connection = <<EOT
provider: Google
google_project: ${var.project_id}
google_client_email: ${google_service_account.gitlab_gcs.email}
google_json_key_string: '${base64decode(google_service_account_key.gitlab_gcs.private_key)}'
EOT
  }
}

resource "kubernetes_secret" "gitlab_registry_storage" {
  metadata {
    name = "gitlab-registry-storage"
  }

  data = {
    "gcs.json" = <<EOT
${base64decode(google_service_account_key.gitlab_gcs.private_key)}
EOT

    storage = <<EOT
gcs:
  bucket: ${var.project_id}-registry
  keyfile: /etc/docker/registry/storage/gcs.json
EOT
  }
}

resource "kubernetes_secret" "gitlab_gcs_credentials" {
  metadata {
    name = "google-application-credentials"
  }

  data = {
    gcs-application-credentials-file = "${base64decode(google_service_account_key.gitlab_gcs.private_key)}"
  }
}

resource "kubernetes_secret" "google_omniauth_provider" {
  metadata {
    name = "gitlab-google-oauth2"
  }

  data = {
    provider = <<EOT
name: google_oauth2
app_id: "${var.omniauth.google_client_id}"
app_secret: "${var.omniauth.google_client_secret}"
args:
  access_type: offline
  approval_prompt: ''
EOT
  }
}

data "helm_repository" "gitlab" {
  name = "gitlab"
  url  = "https://charts.gitlab.io"
}

data "template_file" "helm_values" {
  template = "${file("${path.module}/values.yaml.tpl")}"

  vars = {
    DOMAIN                           = "${var.domain != "" ? var.domain : "gitlab.${google_compute_address.gitlab.address}.xip.io"}"
    INGRESS_IP                       = "${google_compute_address.gitlab.address}"
    DB_PRIVATE_IP                    = "${google_sql_database_instance.gitlab_db.private_ip_address}"
    REDIS_PRIVATE_IP                 = "${google_redis_instance.gitlab.host}"
    PROJECT_ID                       = "${var.project_id}"
    CERT_MANAGER_EMAIL               = "${var.certmanager_email}"
    GITLAB_RUNNER_INSTALL            = "${var.gitlab_runner_install ? "true" : "false"}"
    GITLAB_EDITION                   = "${var.gitlab_edition}"
    OMNIAUTH_ENABLED                 = var.omniauth.enabled
    OMNIAUTH_SSO_PROVIDERS           = jsonencode(var.omniauth.sso_providers)
    OMNIAUTH_SYNC_PROFILE_PROVIDERS  = jsonencode(var.omniauth.sync_profile_providers)
    OMNIAUTH_SYNC_PROFILE_ATTRIBUTES = jsonencode(var.omniauth.sync_profile_attributes)
  }
}

resource "helm_release" "gitlab" {
  name       = "gitlab"
  repository = "${data.helm_repository.gitlab.name}"
  chart      = "gitlab"
  version    = "${var.gitlab_chart_version}"
  timeout    = 600

  values = ["${data.template_file.helm_values.rendered}"]

  depends_on = ["google_redis_instance.gitlab",
    "google_sql_database.gitlabhq_production",
    "google_sql_user.gitlab",
    "kubernetes_cluster_role_binding.tiller-admin",
    "kubernetes_storage_class.pd-ssd",
  ]
}
