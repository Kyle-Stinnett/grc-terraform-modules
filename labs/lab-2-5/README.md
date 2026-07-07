# Lab 2.5 - IaC as Compliance Evidence (AWS)

Builds an S3 Object Lock vault that holds Terraform evidence bundles and refuses deletion by design. A PowerShell capture script collects plan output, state, git log, and Terraform version from a workspace, hashes each file, bundles them into a tar archive, and uploads to the vault with a recorded VersionId. The vault applies a default retention rule to every uploaded object automatically.

## What This Proves

Three properties auditors require for evidence: integrity, attribution, and reproducibility. A screenshot provides none of them. A hashed, versioned, immutably stored Terraform bundle provides all three.

## Controls Demonstrated

| Control | Implementation |
|---|---|
| AU-9 - Protection of Audit Information | S3 Object Lock prevents deletion or modification of evidence during the retention window |
| AU-11 - Audit Record Retention | Default retention rule applied automatically to every uploaded object |
| SI-12 - Information Management | Evidence bundle includes plan, state, git commit, and Terraform version for full reproducibility |

## How It Works

1. capture-evidence.ps1 collects artifacts from a Terraform workspace
2. Each file is SHA-256 hashed and recorded in a manifest
3. The bundle is uploaded to the Object Lock vault
4. S3 applies the bucket default retention rule at upload time
5. A JSON receipt is saved locally with the VersionId as the durable evidence handle

The destructive test in this lab confirms that even an admin with full AWS permissions cannot delete an object within its retention window. The AccessDenied response is the control.

## Evidence Receipt

`evidence/lab-2-5/receipt.json` contains the run ID, vault name, S3 key, VersionId, and capture timestamp for the test bundle uploaded during this lab.
