# Compliance Policy Library (Lab 3.3)

Rego policies that validate a `terraform plan -json` output against NIST SP 800-53 controls before any resource is created. Each policy maps to one control and produces deny messages that include the resource address and the control ID, so a developer can fix their own violation without filing a GRC ticket.

## Policies

| Control | File | Severity | Enforces |
|---|---|---|---|
| SC-28 | `sc28_encryption.rego` | High | Every `google_storage_bucket` must have an `encryption { default_kms_key_name }` block referencing a customer-managed encryption key (CMEK). |
| AC-3 | `ac3_no_public.rego` | Critical | Buckets must set `uniform_bucket_level_access = true` and `public_access_prevention = "enforced"`. Firewall rules must not expose management ports (22, 3389) to `0.0.0.0/0`. |
| CM-6 | `cm6_required_tags.rego` | Medium | Every taggable resource must carry all four required labels: `project`, `environment`, `managed_by`, `compliance_scope`. |

## Remediation

- **SC-28**: Add an `encryption { default_kms_key_name = ... }` block referencing a `google_kms_crypto_key` you control.
- **AC-3**: Set `uniform_bucket_level_access = true` and `public_access_prevention = "enforced"` on buckets. Narrow `source_ranges` or remove the rule on firewalls exposing management ports.
- **CM-6**: Add the missing required labels to the resource.

## Testing

Unit tests live in `tests/`, one file per policy, each asserting both passing and failing fixtures.

```powershell
opa test -v policies/
```

Result: `PASS: 8/8`.

## Evaluating against a real plan

```powershell
opa eval -d policies -i terraform/plan.json data.compliance.sc28.deny --format=pretty
opa eval -d policies -i terraform/plan.json data.compliance.ac3.deny  --format=pretty
opa eval -d policies -i terraform/plan.json data.compliance.cm6.deny  --format=pretty
```

Against this lab's fixture (`terraform/main.tf`), each non-compliant resource is flagged exactly once by the correct control, and the compliant bucket produces no violations. After fixing the fixture, all three deny sets return empty.

## Design note

Policies check for the *presence* of a configured block rather than a resolved value where Terraform can't know the value at plan time. For example, `has_cmek` in `sc28_encryption.rego` accepts any non-empty `encryption` block, because the KMS key ID is `(known after apply)` at plan time and omitted from the JSON entirely. This is correct plan-time semantics: the developer wired CMEK, the value resolves at apply.

## How this feeds the capstone

This library covers GCP resources. Lab 3.4 adds AWS variants targeting `aws_s3_bucket` and related resources, with the combined suite run through Conftest as the gate a CI pipeline calls. Same control IDs, every cloud, one OSCAL component.