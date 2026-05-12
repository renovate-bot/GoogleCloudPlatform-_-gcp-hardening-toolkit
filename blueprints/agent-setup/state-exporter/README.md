# GCP Hardening Toolkit - State Exporter

This directory contains scripts to export the state of your GCP environment for security hardening analysis.

## Prerequisites

Ensure you have the `gcloud` CLI and `bq` command-line tools installed and configured.

## Scripts

- `export_project_state.sh [PROJECT_ID] [BUCKET_NAME]`: Exports both Cloud Asset Inventory (CAI) and Security Command Center (SCC) state for a specific project.
- `export_org_state.sh [ORG_ID] [BILLING_PROJECT_ID] [CAI_DATASET_NAME] [BUCKET_NAME]`: Exports both CAI and SCC state for an entire organization.

## Usage

To run the scripts, navigate to this directory in your terminal and execute the desired script with the required parameters.

### Project-Level Export

Exports CAI and SCC data for a single project.

```bash
./export_project_state.sh YOUR_GCP_PROJECT_ID
```

You can optionally provide a custom GCS bucket name for the SCC findings:

```bash
./export_project_state.sh YOUR_GCP_PROJECT_ID your-custom-bucket-name
```

### Organization-Level Export

Exports CAI and SCC data for an entire organization.

```bash
./export_org_state.sh YOUR_ORG_ID YOUR_BILLING_PROJECT_ID
```

You can also provide custom names for the BigQuery dataset and GCS bucket:

```bash
./export_org_state.sh YOUR_ORG_ID YOUR_BILLING_PROJECT_ID your-custom-dataset your-custom-bucket
```
