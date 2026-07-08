# Compliance Policy Library (Lab 3.4)

Carries the Lab 3.3 Rego library forward and adds AWS-resource-type variants so the same three NIST SP 800-53 controls are enforced regardless of cloud. Six files, three control IDs.

## Policies

| Control | Cloud | File | Severity | Enforces |
|---|---|---|---|---|
| SC-28 | GCP | `sc28_encryption.rego` | High | Every `google_storage_bucket` must have an `encryption { default_kms_key_name }` block referencing a CMEK. |
| SC-28 | AWS | `sc28_encryption_aws.rego` | High | Every `aws_s3_bucket` must have an `aws_s3_bucket_server_side_encryption_configuration` referencing it (matched via `configuration.root_module.resources[].expressions.bucket.references`, since the bucket name is unknown at plan time). |
| AC-3 | GCP | `ac3_no_public.rego` | Critical | Buckets must set `uniform_bucket_level_access = true` and `public_access_prevention = "enforced"`. Firewalls must not expose management ports (22, 3389) to `0.0.0.0/0`. |
| AC-3 | AWS | `ac3_no_public_aws.rego` | Critical | Every `aws_s3_bucket` must have an `aws_s3_bucket_public_access_block` referencing it, with all four flags (`block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets`) set `true`. |
| CM-6 | GCP | `cm6_required_tags.rego` | Medium | Every taggable resource must carry all four required labels: `project`, `environment`, `managed_by`, `compliance_scope`. |
| CM-6 | AWS | `cm6_required_tags_aws.rego` | Medium | Every taggable resource must carry all four required tags: `Project`, `Environment`, `ManagedBy`, `ComplianceScope` (reads `tags_all` when provider `default_tags` is set, falls back to `tags`). |

## The cross-cloud lesson

Running the GCP policies (`compliance.sc28`, `compliance.ac3`) against an AWS plan passes with zero coverage — they check `google_storage_bucket` / `google_compute_firewall`, and there are none in an AWS plan. A control ID (SC-28, AC-3, CM-6) is portable; a Rego rule hardcoded to one cloud's resource types is not. This library keeps each rule readable by adding a per-cloud variant rather than writing one generalized rule for every resource type.

## Why AWS matches by reference, not by value

At `terraform plan` time, values derived from `random_id` (like the bucket name) are `(known after apply)` and appear as `null` in the plan JSON. Matching `aws_s3_bucket.values.bucket == aws_s3_bucket_server_side_encryption_configuration.values.bucket` would compare `null == null` and always pass, even with no relationship between the resources. Instead, the AWS SC-28 and AC-3 rules read `configuration.root_module.resources[].expressions.bucket.references`, which Terraform populates with the literal reference string (e.g. `"aws_s3_bucket.primary.id"`) regardless of whether the value has resolved yet.

## Testing

Unit tests live in `tests/`, one file per policy (GCP and AWS), each asserting both passing and failing fixtures.

```powershell
opa test -v policies/
```

Result: `PASS: 16/16` (8 GCP + 8 AWS).

## Running against a real plan

```powershell
conftest test --policy policies --namespace compliance.sc28_aws plan.json
conftest test --policy policies --namespace compliance.ac3_aws  plan.json
conftest test --policy policies --namespace compliance.cm6_aws  plan.json
conftest test --policy policies --namespace compliance.cm6      plan.json
```

Or run the whole gate at once with `scripts/policy-gate.sh --workspace <path>` (see repo root).

## Design notes

- **SC-28 (AWS)**: matches by Terraform reference, not resolved value — see above.
- **AC-3 (AWS)**: stricter than the GCP version. It requires the `aws_s3_bucket_public_access_block` resource to exist *and* all four flags to be `true` in `planned_values`, since these are static booleans known at plan time (unlike the bucket name).
- **CM-6 (AWS)**: checks `tags_all` first (the provider-merged tag set when `default_tags` is configured) and falls back to `tags` if `tags_all` isn't present, so the rule works whether or not the provider block sets defaults.

## How this feeds the capstone

`scripts/policy-gate.sh` is the exact script CI calls in Lab 4.3. Point it at a Terraform workspace and it runs every namespace in this library, writes a combined JSON evidence file, and exits non-zero on any violation — a fail-closed gate that blocks the merge until the developer fixes the resource the deny message names.
