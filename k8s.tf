module "network" {
  source      = "./network"
  vpc_name    = "vpc-gcp"
  subnet_name = "subnet-gcp"
  region      = "us-central1"
  subnet_cidr = "10.0.0.0/24"
}

resource "google_compute_network_peering" "default_to_vpc_gcp" {
  name         = "default-to-vpc-gcp"
  network      = "projects/${var.project}/global/networks/default"
  peer_network = module.network.vpc_self_link

}

resource "google_compute_network_peering" "vpc_gcp_to_default" {
  name         = "vpc-gcp-to-default"
  network      = module.network.vpc_self_link
  peer_network = "projects/${var.project}/global/networks/default"

}

resource "google_container_cluster" "primary" {
  name                     = var.cluster_name
  location                 = var.location
  network                  = module.network.vpc_self_link
  subnetwork               = module.network.subnet_self_link
  remove_default_node_pool = true
  initial_node_count       = 1

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "10.13.0.0/28"
  }
  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.11.0.0/21"
    services_ipv4_cidr_block = "10.12.0.0/21"
  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = module.network.subnet_cidr
      display_name = "net1"
    }
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = google_container_cluster.primary.name
  location   = var.location
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = "k8s-workers"
    }

    machine_type = "e2-medium"
    preemptible  = true

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}
