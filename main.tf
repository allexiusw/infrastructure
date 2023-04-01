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

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = "us-central1-c"
}

# create the bucket to store terraform state into
resource "google_storage_bucket" "terraform_state"  {
  name    = "easysv-tf-state-dev"
  location  = var.region
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
