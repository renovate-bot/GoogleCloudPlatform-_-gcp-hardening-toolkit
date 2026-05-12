# GCP Hardening Toolkit (GHT)

![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.3-935ADA?style=for-the-badge&logo=terraform&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.x-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-Shell-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![License](https://img.shields.io/badge/License-Apache%202.0-blue?style=for-the-badge)
[![Technical Guides](https://img.shields.io/badge/YouTube-Technical_Guides-CD201F?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/watch?v=hrbTj3YUhlQ&list=PLJKGPxH0mLCrZDBQbSAGP8O_ig2o4iZM9&index=1)

Standard foundational toolkits assume a clean slate. The reality is you are likely dealing with active, undocumented, and messy infrastructure (brownfield environments).

The **GCP Hardening Toolkit (GHT)** is an automated triage and remediation engine built for this exact reality. Its core component is the **Hardening Agent**—an interactive CLI assistant that audits your live environment, identifies security debt, and deploys incremental compliance guardrails using state-aware Infrastructure as Code (IaC) without disrupting active DevOps pipelines.

---

## The Hardening Agent

The Hardening Agent is the brain of the toolkit. Instead of blindly enforcing restrictive policies, it reads your current infrastructure state, analyzes existing vulnerabilities, and generates targeted, safe Terraform blueprints to fix them.

### 1. Prerequisite: Agent Setup Blueprint
Because the Agent grounds its decisions in your live environment data, you must first deploy its restricted infrastructure.

Navigate to `blueprints/agent-setup/` and deploy the setup blueprint. This provisions the least-privilege Service Account, BigQuery datasets, and Cloud Storage buckets the agent needs, alongside the exact bash scripts (`export_org_state.sh` / `export_project_state.sh`) required to safely dump your Cloud Asset Inventory (CAI) and Security Command Center (SCC) data for analysis.

### 2. Installation
Install the Hardening Agent as a Gemini CLI extension:

```bash
gemini extensions install [https://github.com/GoogleCloudPlatform/gcp-hardening-toolkit](https://github.com/GoogleCloudPlatform/gcp-hardening-toolkit)
```
*For complete architecture and command details, see the [Hardening Agent Documentation](agent/README.md).*

---

## The Toolkit Payload (Blueprints & Modules)

The repository provides the raw materials the Agent uses to secure your environment. It is decoupled into two main layers:

*   **Modules (`modules/`):** Reusable, stateless, and minimal wrappers around Terraform resources (e.g., specific org policy constraints).
*   **Blueprints (`blueprints/`):** Deployable, stateful solutions built from modules. The Agent generates or modifies these to fit your specific requirements.

### Core Capabilities

*   **Triage & Remediation:** Automate investigation and decision-making for SCC alerts, reducing alert fatigue and manual review.
*   **Targeted Constraints:** Block lateral movement by deploying precise Org Policies (e.g., restricting service account creation) only where safe.
*   **Frictionless Compliance:** Deploy comprehensive security baselines (like HIPAA or PCI-DSS guardrails) incrementally.
*   **Advanced Detection:** Extend native GCP observability with custom threat detection pipelines and log routing.

---

## GHT vs. Cloud Foundation Toolkit (CFT)

If you are building a new Google Cloud organization from scratch (greenfield), use the [Cloud Foundation Toolkit (CFT)](https://github.com/GoogleCloudPlatform/cloud-foundation-toolkit).

**Use GHT if:**
* You are conducting a Cloud Security Posture Review (CSPR) and need to fix active, messy infrastructure.
* You need to accelerate compliance but cannot afford to break current production operations.
* You want an automated agent to do the heavy lifting of mapping dependencies before applying restrictive policies.

| Feature | Cloud Foundation Toolkit (CFT) | GCP Hardening Agent & Toolkit (GHT) |
| :--- | :--- | :--- |
| **Primary Use Case** | Building new infrastructure (Greenfield). | Triaging and hardening active environments (Brownfield). |
| **Execution** | Static Terraform Blueprints. | Automated Agent + State-Aware IaC. |
| **Environment State** | Assumes a standard "clean slate". | Reads and respects your live, current state and tech debt. |
| **Guardrail Strategy** | Broad, top-down baseline enforcement. | Targeted, triage-based incremental enforcement. |
| **DevOps Friction** | High (if forced onto existing infra). | Low (fixes issues without breaking apps). |

---

## Usage Workflow

If you are not using the interactive Hardening Agent, you can deploy blueprints manually:

1.  **Select:** Choose a solution from `blueprints/` that matches your tactical goal.
2.  **Customize:** Review the `examples` or adjust the `variables.tf` to fit your scope.
3.  **Execute:**
```bash
cd blueprints/gcp-foundation-org-iam
terraform init
terraform apply
```

## Release Cycle & Supply Chain Security

We use a **Rolling Release** model. Every commit to `main` is stable. To protect your production environments from unintended updates, **always pin modules to a specific commit hash**:

```hcl
module "gcp_hardening" {
  source = "[github.com/GoogleCloudPlatform/gcp-hardening-toolkit//modules/gcp-org-policies?ref=](https://github.com/GoogleCloudPlatform/gcp-hardening-toolkit//modules/gcp-org-policies?ref=)<COMMIT_HASH>"
}
```

## Contributing & Feedback
Contributions are welcome. See our [Contributing Guide](docs/contributing.md) for rules of engagement.

To help us prioritize automation features and improve the agent, please share your operational feedback.
[Take the 1-Minute Survey](https://forms.gle/LmgxXbJBoqu91dyA9)
