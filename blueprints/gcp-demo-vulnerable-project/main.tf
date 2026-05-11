terraform {
  required_version = ">= 1.3.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

provider "google" {
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}

# 0. Organization Policy Overrides
# These are required to allow the creation of insecure resources.
resource "google_org_policy_policy" "allow_public_sql" {
  name   = "projects/${var.project_id}/policies/sql.restrictAuthorizedNetworks"
  parent = "projects/${var.project_id}"
  spec {
    rules {
      enforce = "FALSE"
    }
  }
}

resource "google_org_policy_policy" "allow_external_ips" {
  name   = "projects/${var.project_id}/policies/compute.vmExternalIpAccess"
  parent = "projects/${var.project_id}"
  spec {
    rules {
      allow_all = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "disable_shielded_vm" {
  name   = "projects/${var.project_id}/policies/compute.requireShieldedVm"
  parent = "projects/${var.project_id}"
  spec {
    rules {
      enforce = "FALSE"
    }
  }
}

resource "google_org_policy_policy" "disable_uniform_bucket_level_access" {
  name   = "projects/${var.project_id}/policies/storage.uniformBucketLevelAccess"
  parent = "projects/${var.project_id}"
  spec {
    rules {
      enforce = "FALSE"
    }
  }
}

resource "google_org_policy_policy" "disable_public_access_prevention" {
  name   = "projects/${var.project_id}/policies/storage.publicAccessPrevention"
  parent = "projects/${var.project_id}"
  spec {
    rules {
      enforce = "FALSE"
    }
  }
}

resource "google_org_policy_policy" "disable_os_login" {
  name   = "projects/${var.project_id}/policies/compute.requireOsLogin"
  parent = "projects/${var.project_id}"
  spec {
    rules {
      enforce = "FALSE"
    }
  }
}

resource "google_org_policy_policy" "allow_all_domains" {
  name   = "projects/${var.project_id}/policies/iam.allowedPolicyMemberDomains"
  parent = "projects/${var.project_id}"
  spec {
    rules {
      allow_all = "TRUE"
    }
  }
}

# 1. Public GCS Bucket
resource "google_storage_bucket" "public_bucket" {
  name                        = "${var.project_id}-vulnerable-bucket"
  location                    = "US"
  project                     = var.project_id
  force_destroy               = true
  uniform_bucket_level_access = false # Triggers Legacy Access Control finding

  depends_on = [
    google_org_policy_policy.disable_uniform_bucket_level_access,
    google_org_policy_policy.disable_public_access_prevention,
    google_org_policy_policy.allow_all_domains
  ]
}

# 6. Vulnerable GKE Cluster
resource "google_container_cluster" "vulnerable_gke" {
  name               = "vulnerable-gke"
  location           = var.region
  project            = var.project_id
  network            = google_compute_network.vulnerable_network.name
  initial_node_count = 1

  # Insecure: Public endpoint enabled (default, but explicit for clarity)
  # Insecure: Legacy authorization enabled
  enable_legacy_abac = true

  # Insecure: Monitoring/Logging disabled or poorly configured
  monitoring_service = "none"
  logging_service    = "none"

  remove_default_node_pool = true

  # Delete protection disabled for easy cleanup
  deletion_protection = false

  depends_on = [
    google_org_policy_policy.allow_external_ips,
    google_org_policy_policy.disable_shielded_vm,
    google_org_policy_policy.disable_os_login
  ]
}

resource "google_container_node_pool" "vulnerable_nodes" {
  name       = "vulnerable-node-pool"
  location   = var.region
  cluster    = google_container_cluster.vulnerable_gke.name
  project    = var.project_id
  node_count = 1

  node_config {
    machine_type = "e2-medium"

    # Insecure: Broad scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    # Insecure: Metadata concealment disabled
    workload_metadata_config {
      mode = "GCE_METADATA"
    }
  }
}

# 7. Outdated/Legacy VM Configuration
resource "google_compute_instance" "legacy_vm" {
  name         = "legacy-vm"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"
  project      = var.project_id

  boot_disk {
    initialize_params {
      # Using a standard image but keeping other insecure features like OS Login disabled
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vulnerable_network.name
    access_config {
      # Public IP
    }
  }

  metadata = {
    # Insecure: OS Login disabled explicitly
    enable-oslogin = "false"
  }

  service_account {
    scopes = ["cloud-platform"]
  }

  depends_on = [
    google_org_policy_policy.allow_external_ips,
    google_org_policy_policy.disable_shielded_vm,
    google_org_policy_policy.disable_os_login
  ]
}

# 2. Open Firewall Rules
resource "google_compute_network" "vulnerable_network" {
  name                    = "vulnerable-network"
  project                 = var.project_id
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "allow_all_ssh" {
  name    = "allow-all-ssh"
  network = google_compute_network.vulnerable_network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # Triggers Open SSH Port finding
}

resource "google_compute_firewall" "allow_all_rdp" {
  name    = "allow-all-rdp"
  network = google_compute_network.vulnerable_network.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }

  source_ranges = ["0.0.0.0/0"] # Triggers Open RDP Port finding
}

# 3. Vulnerable Compute Instance
resource "google_compute_instance" "vulnerable_vm" {
  name         = "vulnerable-vm"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vulnerable_network.name
    access_config {
      # Giving the instance an external IP address triggers finding
    }
  }

  service_account {
    # Scopes for all Google Cloud APIs
    scopes = ["cloud-platform"]
  }
  # Note: By not specifying an email, it uses the default compute service account.
  # This triggers Default Service Account Used finding.

  depends_on = [
    google_org_policy_policy.allow_external_ips,
    google_org_policy_policy.disable_shielded_vm,
    google_org_policy_policy.disable_os_login
  ]
}

# 4. Excessive IAM Permissions
resource "google_service_account" "overprivileged_sa" {
  account_id   = "overprivileged-sa"
  display_name = "Overprivileged Service Account for Demo"
  project      = var.project_id
}

resource "google_project_iam_member" "editor_binding" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.overprivileged_sa.email}"
  # Triggers IAM Editor Role Assigned finding

  depends_on = [
    google_org_policy_policy.allow_all_domains
  ]
}

# 5. Publicly Accessible SQL Instance
resource "google_sql_database_instance" "vulnerable_sql" {
  name             = "vulnerable-sql"
  region           = var.region
  database_version = "POSTGRES_14"
  project          = var.project_id

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0" # Triggers Public SQL Instance finding
      }
    }
  }
  deletion_protection = false

  depends_on = [
    google_org_policy_policy.allow_public_sql
  ]
}
