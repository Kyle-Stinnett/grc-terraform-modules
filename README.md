# GRC Terraform Modules

This repository contains Terraform modules and primitives built as part of a structured GRC engineering lab series. The focus is on translating compliance controls from NIST SP 800-53 into infrastructure-as-code that enforces security by default rather than by policy alone.

## Repository Structure
---

## Lab 2.3 - Compliant S3 Bucket (AWS)

**Location:** `primitives/compliant-s3`

Provisions a single AWS S3 bucket with a hardcoded compliance configuration. No public access, server-side encryption, versioning, and required tags are enforced directly in the resource declaration. This lab establishes the baseline pattern for encoding controls into infrastructure rather than relying on post-deployment audits.

### Controls Encoded

| Control | Implementation |
|---|---|
| SC-28 - Protection of Information at Rest | AES-256 server-side encryption enforced on all objects |
| AC-3 - Access Enforcement | All four S3 public access block settings enabled |
| AU-11 - Audit Record Retention | Versioning enabled to preserve object history |
| CM-6 - Configuration Settings | Required compliance tags applied at the bucket level |

---

## Lab 2.4 - Terraform Modules for Compliance (GCP)

**Location:** `modules/compliant-gcs-bucket`

Builds a reusable Terraform module that provisions a compliant Google Cloud Storage bucket. Compliance controls are hardcoded inside the module where consumers cannot modify or disable them. A consumer provides only business-relevant inputs like environment and retention duration. The security floor is enforced automatically.

### Controls Encoded

| Control | Implementation |
|---|---|
| SC-12 - Cryptographic Key Establishment | Customer-managed encryption key via Cloud KMS with 90-day automatic rotation |
| SC-13 - Cryptographic Protection | AES-256 encryption enforced on all objects at rest |
| SC-28 - Protection of Information at Rest | CMEK attached to the bucket; no object stored without encryption |
| AC-3 - Access Enforcement | Uniform bucket-level access enabled; public access prevention set to enforced |
| AU-11 - Audit Record Retention | Versioning enabled; configurable retention policy enforced at the module level |
| CM-6 - Configuration Settings | Required compliance labels merged on top of consumer labels and cannot be removed |

### Module Interface

Consumers provide:
- GCP project ID
- Environment (dev, staging, or prod)
- Retention duration in days
- Bucket name suffix

The module enforces everything else. A consumer cannot disable encryption, remove required labels, or set a retention period below 365 days for a production environment. Violations are caught at terraform plan before any resource is created.

### Compliance Attestation Output

Every apply produces a machine-readable attestation confirming the state of all six controls:

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

### Consumers

Three consumer configurations are included:

- `consumers/dev` - development environment, 30-day retention, applied and verified
- `consumers/prod` - production environment, 365-day retention, plan only
- `consumers/negative-test` - intentionally invalid configuration demonstrating that a prod environment with 30-day retention is rejected at plan time with a specific validation error

---

## Lab 2.5 - IaC as Compliance Evidence (AWS)

**Location:** `primitives/evidence-vault`, `scripts/capture-evidence.ps1`

Builds an S3 Object Lock vault that holds Terraform evidence bundles and refuses deletion by design. A PowerShell capture script collects plan output, state, git log, and Terraform version from a workspace, hashes each file, bundles them into a tar archive, and uploads to the vault with a recorded VersionId. The vault applies a default retention rule to every uploaded object automatically.

### What This Proves

Three properties auditors require for evidence: integrity, attribution, and reproducibility. A screenshot provides none of them. A hashed, versioned, immutably stored Terraform bundle provides all three.

### Controls Demonstrated

| Control | Implementation |
|---|---|
| AU-9 - Protection of Audit Information | S3 Object Lock prevents deletion or modification of evidence during the retention window |
| AU-11 - Audit Record Retention | Default retention rule applied automatically to every uploaded object |
| SI-12 - Information Management | Evidence bundle includes plan, state, git commit, and Terraform version for full reproducibility |

### How It Works

1. capture-evidence.ps1 collects artifacts from a Terraform workspace
2. Each file is SHA-256 hashed and recorded in a manifest
3. The bundle is uploaded to the Object Lock vault
4. S3 applies the bucket default retention rule at upload time
5. A JSON receipt is saved locally with the VersionId as the durable evidence handle

The destructive test in this lab confirms that even an admin with full AWS permissions cannot delete an object within its retention window. The AccessDenied response is the control.

### Evidence Receipt

`evidence/lab-2-5/receipt.json` contains the run ID, vault name, S3 key, VersionId, and capture timestamp for the test bundle uploaded during this lab.

---

## Prerequisites

- Terraform >= 1.6
- AWS CLI v2 with a configured profile
- GCP project with billing enabled and gcloud CLI authenticated
- Roles: roles/storage.admin and roles/cloudkms.admin on GCP
- Cloud KMS API enabled on GCP

## Context

This lab series is built around the premise that compliance controls should live in code, not in documentation. By the time a control reaches a Terraform module or a bucket policy, it is no longer aspirational - it is enforced. This repository is part of a broader curriculum covering cloud infrastructure, GRC engineering, and evidence generation for frameworks like NIST SP 800-53 and FedRAMP.