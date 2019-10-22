# Cloud Storage resources

resource "google_storage_bucket" "gitlab-uploads" {
  name     = "${var.project_id}-gitlab-uploads"
  location = "${var.region}"
}

resource "google_storage_bucket" "gitlab-artifacts" {
  name     = "${var.project_id}-gitlab-artifacts"
  location = "${var.region}"
}

resource "google_storage_bucket" "gitlab-lfs" {
  name     = "${var.project_id}-gitlab-lfs"
  location = "${var.region}"
}

resource "google_storage_bucket" "gitlab-packages" {
  name     = "${var.project_id}-gitlab-packages"
  location = "${var.region}"
}

resource "google_storage_bucket" "gitlab-registry" {
  name     = "${var.project_id}-registry"
  location = "${var.region}"
}

resource "google_storage_bucket" "gitlab-pseudo" {
  name     = "${var.project_id}-pseudo"
  location = "${var.region}"
}

resource "google_storage_bucket" "gitlab-runner-cache" {
  name     = "${var.project_id}-runner-cache"
  location = "${var.region}"
}