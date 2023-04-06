variable "project_id" {
  type = string
  default = "easysv-project-dev"
}

variable "region" {
  type = string
  default = "us-central1"
}

variable "tf_state_gcs_dev" {
  type = string
  default = "easysv-tf-state-dev"
}

variable "cluster_name" {
  type = string
  default = "easysv-k8s-0"
}

variable "location" {
  type = string
  default = "us-central1"
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = "us-central1"
}

// Was not able to create the bucket using terraform
// It should be available before terraform start
terraform {
  backend "gcs" {
    bucket = "easysv-bucket-tfstate"
    prefix = "terraform/state"
  }
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

// Cloud build tools partially working
resource "google_cloudbuild_trigger" "filename-trigger-dev" {
  location = "global"
  name = "easysv-cloud-build-dev"

  trigger_template {
    branch_name = "^(main|master)$"
    repo_name   = "easysv"
    project_id = var.project_id
  }

  substitutions = {
    _REPO = "easysv"
  }

  filename = "cloudbuild-dev.gke.yaml"
}

// Cloud build dev-tag tools partially working
resource "google_cloudbuild_trigger" "filename-trigger-dev-tag" {
  location = "global"
  name = "easysv-cloud-build-dev-tag"

  trigger_template {
    tag_name =  "^(dev-.*)$"
    repo_name   = "easysv"
    project_id = var.project_id
  }

  substitutions = {
    _REPO = "easysv"
  }

  filename = "cloudbuild-dev.gke.yaml"
}

resource "google_service_account" "main" {
  account_id   = "${var.cluster_name}-sa"
  display_name = "GKE Cluster ${var.cluster_name} Service Account"
}

resource "google_container_cluster" "main" {
  name               = "${var.cluster_name}"
  location           = var.location
  initial_node_count = 3
  node_config {
    service_account = google_service_account.main.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  timeouts {
    create = "30m"
    update = "40m"
  }
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [google_container_cluster.main]
  create_duration = "30s"
}

module "gke_auth" {
  depends_on           = [time_sleep.wait_30_seconds]
  source               = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  project_id           = var.project_id
  cluster_name         = google_container_cluster.main.name
  location             = var.location
  use_private_endpoint = false
}

provider "kubectl" {
  host                   = module.gke_auth.host
  cluster_ca_certificate = module.gke_auth.cluster_ca_certificate
  token                  = module.gke_auth.token
  load_config_file       = false
}

data "kubectl_file_documents" "namespace" {
    content = file("manifests/argocd/namespace.yaml")
} 

data "kubectl_file_documents" "argocd" {
    content = file("manifests/argocd/install.yaml")
}

resource "kubectl_manifest" "namespace" {
    count     = length(data.kubectl_file_documents.namespace.documents)
    yaml_body = element(data.kubectl_file_documents.namespace.documents, count.index)
    override_namespace = "argocd"
}

resource "kubectl_manifest" "argocd" {
    depends_on = [
      kubectl_manifest.namespace,
    ]
    count     = length(data.kubectl_file_documents.argocd.documents)
    yaml_body = element(data.kubectl_file_documents.argocd.documents, count.index)
    override_namespace = "argocd"
}


data "kubectl_file_documents" "my-nginx-app" {
    content = file("manifests/argocd/my-nginx.yaml")
}

resource "kubectl_manifest" "my-nginx-app" {
    depends_on = [
      kubectl_manifest.argocd,
    ]
    count     = length(data.kubectl_file_documents.my-nginx-app.documents)
    yaml_body = element(data.kubectl_file_documents.my-nginx-app.documents, count.index)
    override_namespace = "argocd"
}
