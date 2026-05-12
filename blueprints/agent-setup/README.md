# GCP Hardening Agent Setup Blueprint

This blueprint deploys the least-privilege infrastructure (Service Account, IAM roles, BigQuery dataset, GCS bucket) required to run the GCP Hardening Agent and export your security telemetry safely.

## 1. Prerequisites

Before deploying, make sure you have the right tools and access.

* **Tools:** Terraform >= 1.3.0, `gcloud` CLI, and `bq` CLI.
* **Permissions:** You need `Owner` or `IAM Admin` on the target GCP project to create the Service Account and custom roles.
* **APIs:** The Identity and Access Management (IAM) and Cloud Resource Manager APIs must be enabled.

Run this to enable the APIs:
```bash
gcloud services enable iam.googleapis.com cloudresourcemanager.googleapis.com
```

---

## 2. Deploy the Infrastructure

This step creates the dedicated Service Account, custom IAM role, BigQuery dataset, and Cloud Storage bucket.

**Initialize Terraform:**
```bash
terraform init
```

**Set your target project:**
Create a `terraform.tfvars` file and add your project ID:
```hcl
project_id = "your-project-id"
```

**Deploy:**
```bash
terraform plan
terraform apply
```

---

## 3. Export Your State & Run the Agent

Once the infrastructure is up, you need to pull your Cloud Asset Inventory (CAI) and Security Command Center (SCC) data into the new BigQuery dataset and GCS bucket.

Terraform dynamically generates the exact commands you need to run based on your deployment.

**Get your custom execution instructions:**
```bash
terraform output setup_instructions
```

The output will give you the exact copy-paste commands for the following two phases:

### Phase A: State Export
You will use one of the two included bash scripts to dump your environment data. The Terraform output provides the exact flags.
* **`export_project_state.sh`**: Dumps CAI and SCC data for a single project.
* **`export_org_state.sh`**: Dumps CAI and SCC data for the entire organization.

### Phase B: Agent Execution
Finally, the output will provide the commands to configure Service Account Impersonation and execute the Hardening Agent against the telemetry you just exported. Follow those terminal commands to start the analysis.
