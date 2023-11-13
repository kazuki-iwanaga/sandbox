# ==============================================================================
# Service Account for Github Actions
# ==============================================================================
resource "google_service_account" "github_actions" {
  account_id   = var.sa_github_actions
  display_name = "SA for Github Actions"
  description  = "SA for Github Actions"

  project = var.project
}

resource "google_project_iam_member" "github_actions" {
  for_each = toset([
    "roles/storage.admin",
    "roles/resourcemanager.projectIamAdmin",
  ])

  role   = each.value
  member = "serviceAccount:${google_service_account.github_actions.email}"

  project = var.project
}
# ==============================================================================

# ==============================================================================
# Workload Identity Pool and Provider
# ==============================================================================
resource "google_iam_workload_identity_pool" "github_actions" {
  workload_identity_pool_id = "github-actions"
  display_name              = "WIF Pool for Github Actions"
  description               = "WIF Pool for Github Actions"

  project = var.project
}

resource "google_iam_workload_identity_pool_provider" "github_actions" {
  workload_identity_pool_provider_id = "github-actions"
  display_name                       = "WIF Provider for Github Actions"
  description                        = "WIF Provider for Github Actions"

  project = var.project

  workload_identity_pool_id = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_actions" {
  service_account_id = google_service_account.github_actions.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/attribute.repository/${var.gh_repo}"
}
# ==============================================================================