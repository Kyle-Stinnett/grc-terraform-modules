# Lab 2.4 - Terraform Modules for Compliance (GCP)

Builds a reusable Terraform module that provisions a compliant Google Cloud Storage bucket. Compliance controls are hardcoded inside the module where consumers cannot modify or disable them. A consumer provides only business-relevant inputs like environment and retention duration. The security floor is enforced automatically.

## Controls Encoded

| Control | Implementation |
|---|---|
| SC-12 - Cryptographic Key Establishment | Customer-managed encryption key via Cloud KMS with 90-day automatic rotation |
| SC-13 - Cryptographic Protection | AES-256 encryption enforced on all objects at rest |
| SC-28 - Protection of Information at Rest | CMEK attached to the bucket; no object stored without encryption |
| AC-3 - Access Enforcement | Uniform bucket-level access enabled; public access prevention set to enforced |
| AU-11 - Audit Record Retention | Versioning enabled; configurable retention policy enforced at the module level |
| CM-6 - Configuration Settings | Required compliance labels merged on top of consumer labels and cannot be removed |

## Module Interface

Consumers provide:
- GCP project ID
- Environment (dev, staging, or prod)
- Retention duration in days
- Bucket name suffix

The module enforces everything else. A consumer cannot disable encryption, remove required labels, or set a retention period below 365 days for a production environment. Violations are caught at terraform plan before any resource is created.

## Compliance Attestation Output

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

## Consumers

Three consumer configurations are included:

- `consumers/dev` - development environment, 30-day retention, applied and verified
- `consumers/prod` - production environment, 365-day retention, plan only
- `consumers/negative-test` - intentionally invalid configuration demonstrating that a prod environment with 30-day retention is rejected at plan time with a specific validation error
