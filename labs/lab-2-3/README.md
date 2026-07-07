# Compliant S3 Bucket — Terraform IaC Portfolio

A production-pattern AWS S3 implementation demonstrating compliance-by-default 
infrastructure using Terraform. Built as part of a GRC engineering portfolio 
focused on the intersection of Infrastructure as Code and NIST 800-53 control 
implementation.

## What This Does

Provisions two S3 buckets (primary data + logging) with security controls 
enforced at the infrastructure layer — not as policy documents, but as 
code that cannot be accidentally misconfigured.

## Controls Implemented

| Control | NIST 800-53 | Implementation |
|--------|-------------|----------------|
| Encryption at rest | SC-28 | AES-256 SSE-S3, SSE-C blocked |
| Public access | AC-3 | All four public access vectors explicitly denied |
| Versioning | CM-6 | Object versioning enabled for audit trail and recovery |
| Compliance tagging | CM-6 | Project, Environment, ManagedBy, ComplianceScope tags applied to every resource by default |

## Why This Matters for GRC

Traditional compliance relies on humans remembering to configure controls 
correctly. IaC compliance shifts that burden to code — controls are enforced 
at deployment, verified through state files, and auditable without manual 
inspection of individual resources.

The evidence/ folder pattern used here (terraform show -json) produces 
machine-readable compliance artifacts suitable for audit consumption without 
screenshots or manual testing.

## Stack

- Terraform >= 1.6
- AWS Provider ~> 5.0
- Region: us-east-1

## Evidence Collection

terraform show -json tfplan > evidence/plan.json
terraform show -json > evidence/state.json

## Verification

aws s3api