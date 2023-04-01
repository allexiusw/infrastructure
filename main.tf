
provider "google" {
  project = "easysv-project-dev"
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_cloudbuild_trigger" "filename-trigger" {
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
