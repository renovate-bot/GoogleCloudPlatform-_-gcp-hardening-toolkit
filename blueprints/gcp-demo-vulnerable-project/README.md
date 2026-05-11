# GCP Demo: Vulnerable Project

This blueprint creates a GCP project with intentional security vulnerabilities. It is used to demonstrate how **Security Command Center (SCC)** detects issues and how the **GHT Hardening Agent** triages them.

## 🚨 MANDATORY: SECURITY WARNINGS
*   **NEVER deploy this in a production environment.**
*   **PROJECT IS INSECURE:** This blueprint creates public buckets, open firewalls, and overprivileged accounts.
*   **DELETE IMMEDIATELY:** You **must** run `terraform destroy` as soon as you finish your demo. Leaving these resources active is a major security risk.

## What is created?

| Vulnerability | Resource | SCC Finding Type (Typical) |
| :--- | :--- | :--- |
| **Public GCS Bucket** | `google_storage_bucket` | `PUBLIC_BUCKET_ACL` |
| **Legacy Access Control** | `google_storage_bucket` | `LEGACY_BUCKET_IAM` |
| **Open SSH Port (0.0.0.0/0)** | `google_compute_firewall` | `OPEN_FIREWALL` |
| **Open RDP Port (0.0.0.0/0)** | `google_compute_firewall` | `OPEN_FIREWALL` |
| **Public External IP** | `google_compute_instance` | `EXTERNAL_IP_ADDRESS` |
| **Default Service Account Usage** | `google_compute_instance` | `DEFAULT_SERVICE_ACCOUNT_USED` |
| **Excessive IAM Permissions** | `google_project_iam_member` | `IAM_EDITOR_ROLE_ASSIGNED` |
| **Public SQL Instance** | `google_sql_database_instance` | `PUBLIC_SQL_INSTANCE` |
| **Legacy GKE ABAC** | `google_container_cluster` | `GKE_LEGACY_AUTHORIZATION_ENABLED` |
| **GKE Metadata Concealment Disabled** | `google_container_node_pool` | `GKE_METADATA_CONCEALMENT_DISABLED` |
| **OS Login Disabled** | `google_compute_instance` | `OS_LOGIN_DISABLED` |

## Intentional Vulnerabilities
This project intentionally includes:
*   **Public SQL:** Cloud SQL with public IP and `0.0.0.0/0` authorized networks.
*   **Open Firewalls:** Ports 22 and 3389 open to the world.
*   **Overprivileged IAM:** Service account with `roles/editor`.
*   **Vulnerable VM:** Public IP, default service account, and broad scopes.
*   **Legacy GCS:** Bucket with Uniform Bucket Level Access disabled.
*   **Insecure GKE:** Legacy ABAC enabled, monitoring/logging disabled, and metadata concealment disabled.

## Prerequisites

Before deploying this blueprint, you must enable the required APIs. Organization Policy overrides are **automated** within the Terraform configuration and will be applied to the project during deployment.

### 1. Enable Required APIs
```bash
gcloud services enable \
    compute.googleapis.com \
    storage.googleapis.com \
    sqladmin.googleapis.com \
    iam.googleapis.com \
    container.googleapis.com \
    orgpolicy.googleapis.com \
    --project=YOUR_PROJECT_ID
```

## Deployment

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Plan the deployment:
   ```bash
   terraform plan
   ```

3. Apply the blueprint:
   ```bash
   terraform apply -auto-approve
   ```

## Cleanup (MANDATORY)

To eliminate ongoing costs and severe security risks, you **must** destroy the resources immediately after the demonstration:
```bash
terraform destroy -var="project_id=YOUR_PROJECT_ID"
```
**Failure to cleanup may result in unauthorized exploitation of the vulnerable resources.**
