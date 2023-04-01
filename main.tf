
provider "google" {
  project = "easysv-project-dev"
  region  = "us-central1"
  zone    = "us-central1-c"
}

// Cloud build tools partially working
resource "google_cloudbuild_trigger" "filename-trigger-dev" {
  location = "global"
  name = "easysv-cloud-build-dev"

  trigger_template {
    branch_name = "^(main|master)$"
    repo_name   = "easysv"
    project_id = "easysv-project-dev"
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
    project_id = "easysv-project-dev"
  }

  substitutions = {
    _REPO = "easysv"
  }

  filename = "cloudbuild-dev.gke.yaml"
}
