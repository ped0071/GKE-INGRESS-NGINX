variable "region" {
  description = "The name of the VPC."
  default = "us-central1"
}

variable "project" {
  description = "The name of the project."
  default = "k8s-project-392918"
}

variable "location" {
  description = "The name of the location."
  default = "us-central1-a"
}

variable "cluster_name" {
  description = "The name of the cluster."
  default = "k8s-cluster"
}

variable "ssh_key_file" {
  description = "The path to the SSH key file."
  default = ""
}
