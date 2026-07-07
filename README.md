# GRC Terraform Modules

A structured lab series translating NIST SP 800-53 compliance controls into infrastructure-as-code that enforces security by default rather than by policy alone. Each lab builds on the last, moving from single hardcoded resources toward reusable modules, tamper-evident evidence, and automated policy validation ahead of a multi-cloud capstone.

## Labs

| Lab | Title | Cloud | Focus |
|---|---|---|---|
| [2.3](labs/lab-2-3) | Compliant S3 Bucket | AWS | Baseline pattern: hardcoding controls into a single resource |
| [2.4](labs/lab-2-4) | Terraform Modules for Compliance | GCP | Reusable module with enforced controls consumers cannot disable |
| [2.5](labs/lab-2-5) | IaC as Compliance Evidence | AWS | Object Lock evidence vault; hashed, versioned, immutable evidence bundles |
| [3.3](labs/lab-3-3) | Compliance Policies in Rego | GCP | Rego policy library validating a Terraform plan against NIST controls before apply |

## Prerequisites

- Terraform >= 1.6
- AWS CLI v2 with a configured profile
- GCP project with billing enabled and gcloud CLI authenticated
- Roles: roles/storage.admin and roles/cloudkms.admin on GCP
- Cloud KMS API enabled on GCP
- OPA >= 0.60.0 (Lab 3.3 onward)

## Context

This lab series is built around the premise that compliance controls should live in code, not in documentation. By the time a control reaches a Terraform module, a bucket policy, or a Rego rule, it is no longer aspirational, it is enforced. This repository is part of a broader curriculum covering cloud infrastructure, GRC engineering, and evidence generation for frameworks like NIST SP 800-53 and FedRAMP.
