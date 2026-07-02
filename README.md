# GRC Terraform Modules

This repository contains reusable Terraform modules built as part of a structured GRC engineering lab series. The focus is on translating compliance controls from frameworks like NIST SP 800-53 into infrastructure-as-code that enforces security by default rather than by policy alone.

## What This Repository Contains

### Lab 2.4 — Terraform Modules for Compliance (GCP)

**Location:** `modules/compliant-gcs-bucket`

This lab builds a reusable Terraform module that provisions a compliant Google Cloud Storage bucket. The key shift from a standard bucket deployment is that compliance controls are hardcoded inside the module where consumers cannot modify or disable them. A consumer calling this module provides only business-relevant inputs like environment and retention duration. The security floor is enforced automatically.

#### Controls Encoded

| Control | Implementation |
|---|---|
| SC-12 — Cryptographic Key Establishment | Customer-managed encryption key (CMEK) via Cloud KMS with 90-day automatic rotation |
| SC-13 — Cryptographic Protection | AES-256 encryption enforced on all objects at rest |
| SC-28 — Protection of Information at Rest | CMEK attached to the bucket; no object can be stored without encryption |
| AC-3 — Access Enforcement | Uniform bucket-level access enabled; public access prevention set to enforced |
| AU-11 — Audit Record Retention | Versioning enabled; configurable retention policy enforced at the module level |
| CM-6 — Configuration Settings | Required compliance labels (project, environment, managed_by, compliance_scope) merged on top of any consumer-supplied labels and cannot be removed |

#### Module Interface

Consumers provide:
- GCP project ID
- Environment (dev, staging, or prod)
- Retention duration in days
- Bucket name suffix

The module enforces everything else. A consumer cannot disable encryption, remove required labels, or set a retention period below 365 days for a production environment. Violations are caught at `terraform plan` before any resource is created.

#### Compliance Attestation Output

Every apply produces a machine-readable attestation output confirming the state of all six controls:

```hcl
attestation = {
  "encryption_algorithm"     = "google-managed-cmek-aes256"
  "kms_rotation_period"      = "7776000s"
  "public_access_prevention" = "enforced"
  "required_labels_present"  = true
  "retention_period_days"    = 30
  "uniform_access_enforced"  = true
  "versioning_enabled"       = true
}
```

This output is designed to feed downstream tooling including Rego policy evaluation and OSCAL evidence generation in later labs.

#### Consumers

Three consumer configurations are included:

- `consumers/dev` — development environment, 30-day retention, applied and verified
- `consumers/prod` — production environment, 365-day retention, plan only
- `consumers/negative-test` — intentionally invalid configuration demonstrating that a prod environment with 30-day retention is rejected at plan time with a specific validation error

## Prerequisites

- Terraform >= 1.6
- GCP project with billing enabled
- `gcloud` CLI authenticated with both interactive and Application Default Credentials
- Roles: `roles/storage.admin` and `roles/cloudkms.admin`
- Cloud KMS API enabled

## Usage

```hcl
module "data_bucket" {
  source = "./modules/compliant-gcs-bucket"

  gcp_project        = "your-gcp-project"
  project_label      = "your-label"
  environment        = "dev"
  retention_days     = 30
  bucket_name_suffix = "your-unique-suffix"
}
```

## Context

This lab series is built around the premise that compliance controls should live in code, not in documentation. By the time a control reaches a Terraform module, it is no longer aspirational — it is enforced. This repository is part of a broader curriculum covering cloud infrastructure, GRC engineering, and evidence generation for frameworks like NIST SP 800-53 and FedRAMP.
