resource "google_compute_address" "internal_ip_addr" {
  project      = var.project
  address_type = "INTERNAL"
  region       = var.region
  subnetwork   = module.network.subnet_self_link
  name         = "ip-gcp"
  address      = "10.0.0.7"
  description  = "IP interno para conexão com Masternode"
}

resource "google_compute_instance" "default" {
  project      = var.project
  zone         = var.location
  name         = "k8s-ansible"
  machine_type = "e2-medium"

  depends_on = [
    module.network
  ]

  tags = ["ansible"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network    = module.network.vpc_self_link
    subnetwork = module.network.subnet_self_link
    network_ip = google_compute_address.internal_ip_addr.address
  }

  metadata = {
    ssh-keys = var.ssh_key_file
  }
}

resource "google_compute_firewall" "rules" {
  project = var.project
  name    = "allow-ssh"
  network = module.network.vpc_self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_firewall" "ssh_rule" {
  project = var.project
  name    = "myip-ssh"
  network = module.network.vpc_self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["189.36.131.151/32"]
}

resource "google_compute_firewall" "internal_network_rule" {
  project = var.project
  name    = "allow-internal-network"
  network = module.network.vpc_self_link

  allow {
    protocol = "all"
  }
  source_ranges = ["10.0.0.0/24"]
}

resource "google_compute_firewall" "internal_network_rule_default" {
  project = var.project
  name    = "allow-internal-network-default"
  network = module.network.vpc_self_link

  allow {
    protocol = "all"
  }
  source_ranges = ["10.128.0.0/20"]
}
