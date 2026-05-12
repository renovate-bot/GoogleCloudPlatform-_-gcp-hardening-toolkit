# GCP Hardening Agent Setup Blueprint

This blueprint automates the creation of the restricted infrastructure required to run the GCP Hardening Agent following the principle of least privilege.

## What's included:
- **Service Account**: A dedicated identity for the agent.
- **Custom IAM Role**: A restricted role with only the necessary BigQuery and Storage read permissions.
- **BigQuery Dataset**: A central hub for your environment's security telemetry and asset inventory.

## Prerequisites
- Terraform >= 1.3.0
- A GCP Project where you have `Owner` or `IAM Admin` permissions (to create the SA and roles).

## Usage

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

## Post-Deployment

After applying this blueprint, follow the instructions provided in the Terraform outputs to finish setting up the agent.
```bash
terraform output setup_instructions
```
