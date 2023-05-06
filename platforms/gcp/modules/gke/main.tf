# VPC and subnetworks created for a VPC native k8s cluster
# I chose to create them in the same module as they are linked
# Requires the cloudresourcemanager API enabled.
resource "google_project_service" "compute" {
  project = var.project
  service = "compute.googleapis.com"

  disable_dependent_services = false
}

resource "google_project_service" "gke" {
  project = var.project
  service = "container.googleapis.com"

  disable_dependent_services = false
}

resource "google_compute_network" "vpc_network" {
  project     = var.project
  name        = "gke-vpc-network"
  description = "a GKE dedicated VPC."

  auto_create_subnetworks = false

  depends_on = [google_project_service.compute]
}

resource "google_compute_subnetwork" "vpc_node_subnetwork" {
  project     = var.project
  name        = "gke-vpc-node-subnetwork"
  description = "a node subnetwork for GKE"

  region  = var.region
  network = google_compute_network.vpc_network.id

  ip_cidr_range = "10.0.0.0/27"
  secondary_ip_range = [
    {
      range_name    = "gke-vpc-pod-subnetwork"
      ip_cidr_range = "172.16.0.0/24"
    },
    {
      range_name    = "gke-vpc-svc-subnetwork"
      ip_cidr_range = "172.16.1.0/24"
    },
  ]
}

resource "google_container_cluster" "gke" {
  project     = var.project
  name        = "gke-cluster"
  description = "a GKE cluster"

  location        = var.zone
  networking_mode = "VPC_NATIVE"
  network         = google_compute_network.vpc_network.id
  subnetwork      = google_compute_subnetwork.vpc_node_subnetwork.id
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-vpc-pod-subnetwork"
    services_secondary_range_name = "gke-vpc-svc-subnetwork"
    # cluster_ipv4_cidr_block  = "172.16.0.0/24"
    # services_ipv4_cidr_block = "172.16.1.0/24"
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  resource_labels = var.labels

  depends_on = [google_project_service.gke]
}

resource "google_service_account" "gke_service_account" {
  project      = var.project
  account_id   = "gke-service-role"
  display_name = "GKE assigned service account"
}

resource "google_container_node_pool" "gke_node_pool_preemptive" {
  project = var.project
  name    = "gke-preemptive-node-pool"

  cluster           = google_container_cluster.gke.id
  node_count        = 1
  max_pods_per_node = 32

  node_config {
    service_account = google_service_account.gke_service_account.email

    resource_labels = var.labels
    # metadata = {

    # }
    # labels =

    machine_type = "e2-standard-2"
    preemptible  = true
    disk_type    = "pd-standard"
    disk_size_gb = 10
    image_type   = "cos_containerd"
  }
}
