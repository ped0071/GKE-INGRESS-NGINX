resource "google_compute_router" "router" {
  project = var.project
  name    = "nat-router"
  network = module.network.vpc_self_link
  region  = var.region
}

module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.2"
  project_id = var.project
  region     = var.region
  router     = google_compute_router.router.name
  name       = "nat-config"
}
