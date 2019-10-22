# GKE Cluster
resource "google_project_service" "gke" {
  project            = "${var.project_id}"
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_container_cluster" "gitlab" {
  project            = "${var.project_id}"
  name               = "gitlab"
  location           = "${var.region}"
  min_master_version = "${var.gke_min_version}"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true

  initial_node_count = 1

  network    = "${google_compute_network.gitlab.self_link}"
  subnetwork = "${google_compute_subnetwork.us-central.self_link}"

  ip_allocation_policy {
    # Allocate ranges automatically
    cluster_ipv4_cidr_block  = ""
    services_ipv4_cidr_block = ""
  }

  enable_legacy_abac = "${var.gke_enable_abac}"

  # Setting an empty username and password explicitly disables basic auth
  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = true
    }
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  depends_on = ["google_project_service.gke"]
}

resource "google_container_node_pool" "gitlab" {
  name     = "gitlab"
  location = "${var.region}"

  cluster    = "${google_container_cluster.gitlab.name}"
  node_count = 1
  depends_on = []

  node_config {
    preemptible  = false
    machine_type = "${var.gke_default_pool_nodes_type}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "kubernetes_service_account" "tiller" {
  metadata {
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "tiller-admin" {
  metadata {
    name = "tiller-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "tiller"
    namespace = "kube-system"
  }
}

resource "kubernetes_storage_class" "pd-ssd" {
  metadata {
    name = "pd-ssd"
  }

  storage_provisioner = "kubernetes.io/gce-pd"

  parameters = {
    type = "pd-ssd"
  }
}
