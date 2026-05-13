# GCP Hardening Agent

The GCP Hardening Agent is a professional security engineering assistant designed to triage Google Cloud environments and generate actionable hardening blueprints. It operates as a specialized extension for the **Gemini CLI**, enabling an interactive and automated approach to managing security debt in complex, brownfield environments.

## Installation

To install the Hardening Agent as a Gemini CLI extension, run:

```bash
gemini extensions install https://github.com/GoogleCloudPlatform/gcp-hardening-toolkit
```

After installation, link the extension to your local repository:
```bash
gemini extensions link .
```


## Setup

For the agent to have full capabilities, you need to set up the necessary GCP infrastructure (Service Account, IAM roles, BigQuery dataset).

The recommended way to do this is by following the instructions in the [agent-setup blueprint](../blueprints/agent-setup/README.md).

## Usage

To start the agent, run `gemini` from the root of the `gcp-hardening-toolkit` repository.

### Example Prompts

Here are some examples of requests you can make:

*   **Postural Analysis:** `"Can you analyze my exported asset inventory in BigQuery and identify any public IP addresses assigned to Compute Engine instances?"`
*   **IAM Audit:** `"List all service accounts that have primitive owner or editor roles assigned in the project."`
*   **Blueprint Generation:** `"Help me generate a Terraform blueprint to block service account creation using organization policies, referring to the stateless modules available in the repo."`
