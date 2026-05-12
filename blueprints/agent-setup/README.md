# GCP Hardening Agent Setup Blueprint

This blueprint automates the creation of the restricted infrastructure required to run the GCP Hardening Agent following the principle of least privilege.

## What's included:
- **Service Account**: A dedicated identity for the agent.
- **Custom IAM Role**: A restricted role with only the necessary BigQuery and Storage read permissions.
- **BigQuery Dataset**: A central hub for your environment's security telemetry and asset inventory.

## Prerequisites
- Terraform >= 1.3.0
- A GCP Project where you have `Owner` or `IAM Admin` permissions (to create the SA and roles).

### Required APIs
The following APIs must be enabled in your GCP project for this blueprint to function correctly:

- Identity and Access Management (IAM) API
- Cloud Resource Manager API

You can enable them using the `gcloud` CLI:
```bash
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

## Usage

This blueprint automates the creation of the restricted infrastructure required to run the GCP Hardening Agent following the principle of least privilege. The process involves three main steps:

### 1. Deploy Infrastructure (Terraform)

First, deploy the necessary infrastructure (Service Account, BigQuery Dataset, GCS Bucket) using Terraform. This step might require enabling certain APIs in your project, as listed in the "Required APIs" section.

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Create a `terraform.tfvars` file:
   ```hcl
   project_id = "your-project-id"
   ```

3. Plan and Apply:
   ```bash
   terraform plan
   terraform apply
   ```

### 2. Export Environment State

After deploying the infrastructure, you need to export your GCP environment's state (Cloud Asset Inventory and Security Command Center findings) to the BigQuery dataset and GCS bucket created by Terraform. Use the `setup_instructions` output from Terraform to get the exact commands to run the state exporter scripts.

```bash
terraform output setup_instructions
```
Follow the instructions provided by the output to execute the appropriate state exporter script.

### 3. Run the Hardening Agent

Once the environment state has been exported, you can run the Hardening Agent. The `setup_instructions` output from Terraform will also provide the necessary commands to set up your environment for running the agent using Service Account Impersonation.

```bash
terraform output setup_instructions
```
Follow the instructions provided by the output to run the agent.

## State Exporter Scripts

This blueprint includes scripts to export the state of your GCP environment for security hardening analysis.

### Prerequisites

Ensure you have the `gcloud` CLI and `bq` command-line tools installed and configured.

### Scripts

- `export_project_state.sh [PROJECT_ID] [BUCKET_NAME] [DATASET_ID]`: Exports both Cloud Asset Inventory (CAI) and Security Command Center (SCC) state for a specific project.
- `export_org_state.sh [ORG_ID] [BUCKET_NAME] [DATASET_ID]`: Exports both CAI and SCC state for an entire organization.

### Usage

The `setup_instructions` output from Terraform will provide the exact commands to run these scripts with the correct arguments.
