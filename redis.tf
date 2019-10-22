# Cloud Memorystore for Redis configuration

resource "google_project_service" "redis" {
  project            = "${var.project_id}"
  service            = "redis.googleapis.com"
  disable_on_destroy = false
}

resource "google_redis_instance" "gitlab" {
  name               = "gitlab"
  tier               = "${var.redis_tier}"
  memory_size_gb     = "${var.redis_size_gb}"
  region             = "${var.region}"
  authorized_network = "${google_compute_network.gitlab.self_link}"

  depends_on = ["google_project_service.redis"]

  location_id             = "${var.region}-a"
  alternative_location_id = "${var.region}-c"
  display_name            = "GitLab Redis"
}