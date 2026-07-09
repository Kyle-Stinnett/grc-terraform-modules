# Lab 4.3 - GRC Evidence Pipeline (AWS + GitHub Actions)
Wires the Conftest + tfsec gate from Lab 3.4 into GitHub Actions so it runs on every pull request instead of only on a laptop. AWS credentials come from a GitHub OIDC trust relationship, not long-lived keys. Every run, pass or fail, uploads a named evidence artifact.
## What This Proves
A local policy gate proves the tool works. A CI gate proves the control is enforced across the whole team, on every change, without depending on any one person remembering to run it. The workflow file itself is the control statement, and its run history is the evidence that the control operated.
## Controls Demonstrated
| Control | Implementation |
|---|---|
| CM-3 - Configuration Change Control | `on: pull_request` triggers the gate on every proposed change before merge |
| CM-6 - Configuration Settings | Conftest evaluates the Terraform plan against the SC-28/AC-3/CM-6 policies from Lab 3.4 |
| CA-2 / CA-7 - Control Assessments / Continuous Monitoring | The workflow is itself a continuous assessment, re-run on every PR against `labs/lab-2-3` |
| RA-5 - Vulnerability Monitoring and Scanning | tfsec scans the same plan; fails closed on any `error`-level finding, with exceptions tracked centrally in `.tfsec/config.yml` rather than scattered `--exclude` flags |
| AU-9 - Protection of Audit Information | Evidence artifact `grc-evidence-<run-id>` (plan.json, conftest-results.json, tfsec.sarif, plan.txt) uploaded on every run via `if: always()`, retained 90 days |
## How It Works
1. A PR against `master` triggers `.github/workflows/grc-gate.yml`
2. `aws-actions/configure-aws-credentials` assumes `arn:aws:iam::469938015686:role/cgep-grc-gate` via OIDC - no stored AWS keys anywhere in GitHub
3. `terraform plan` runs against `labs/lab-2-3` (the Lab 2.3 compliant S3 bucket)
4. Conftest evaluates the plan against `labs/lab-3-4/policies` under all four namespaces (`compliance.sc28_aws`, `compliance.ac3_aws`, `compliance.cm6_aws`, `compliance.cm6`) - fails closed on any violation
5. tfsec scans the same Terraform, fails closed on any `error`-level finding not explicitly suppressed in `.tfsec/config.yml`
6. The evidence artifact uploads regardless of pass/fail, so a blocked PR still leaves a full audit trail
## Real Run, Not a Staged One
The first run against this pipeline caught a genuine tfsec finding: `aws-s3-encryption-customer-key`, flagging that Lab 2.3's S3 buckets use SSE-S3 (AES256) rather than a customer-managed KMS key. That gap was already called out in Lab 2.3's own code comments as deferred to a later lab. Rather than scope-creep this lab into building KMS infrastructure, the exception was documented and centrally tracked in `.tfsec/config.yml` with a stated justification, and a real, unrelated gap (missing versioning on the log bucket) was fixed in the same pass. The pipeline went red, then green, on real findings.
- Red run (real finding, gate failed closed): https://github.com/Kyle-Stinnett/grc-terraform-modules/actions/runs/29031689464
- Green run (documented exception + real fix): https://github.com/Kyle-Stinnett/grc-terraform-modules/actions/runs/29031971633
- Merged PR: https://github.com/Kyle-Stinnett/grc-terraform-modules/pull/1
## Setup
- `oidc/main.tf` creates the GitHub OIDC provider and a read-only IAM role scoped to `repo:Kyle-Stinnett/grc-terraform-modules:*` via `StringLike` on the trust policy's `sub` claim
- The role ARN is stored as the `AWS_ROLE_ARN` repo variable, referenced in the workflow as `${{ vars.AWS_ROLE_ARN }}`
- `.tfsec/config.yml` at the repo root centralizes suppressions with justifications; the workflow points tfsec at it explicitly with `--config-file`, since tfsec only auto-loads a `.tfsec/` folder relative to the directory it's scanning, not the repo root
