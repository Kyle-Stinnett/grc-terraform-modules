# policies/tests/ac3_no_public_aws_test.rego
package compliance.ac3_aws_test

import rego.v1
import data.compliance.ac3_aws

compliant_input := {
	"configuration": {"root_module": {"resources": [
		{"type": "aws_s3_bucket", "name": "primary"},
		{
			"type": "aws_s3_bucket_public_access_block",
			"name": "primary",
			"expressions": {"bucket": {"references": ["aws_s3_bucket.primary.id"]}},
		},
	]}},
	"planned_values": {"root_module": {"resources": [{
		"address": "aws_s3_bucket_public_access_block.primary",
		"type": "aws_s3_bucket_public_access_block",
		"values": {
			"block_public_acls": true,
			"block_public_policy": true,
			"ignore_public_acls": true,
			"restrict_public_buckets": true,
		},
	}]}},
}

missing_pab_input := {"configuration": {"root_module": {"resources": [
	{"type": "aws_s3_bucket", "name": "bad"},
]}}}

incomplete_pab_input := {
	"configuration": {"root_module": {"resources": [
		{"type": "aws_s3_bucket", "name": "partial"},
		{
			"type": "aws_s3_bucket_public_access_block",
			"name": "partial",
			"expressions": {"bucket": {"references": ["aws_s3_bucket.partial.id"]}},
		},
	]}},
	"planned_values": {"root_module": {"resources": [{
		"address": "aws_s3_bucket_public_access_block.partial",
		"type": "aws_s3_bucket_public_access_block",
		"values": {
			"block_public_acls": true,
			"block_public_policy": true,
			"ignore_public_acls": true,
			"restrict_public_buckets": false,
		},
	}]}},
}

test_compliant_passes if { count(ac3_aws.deny) == 0 with input as compliant_input }

test_missing_pab_fails if {
	some msg in ac3_aws.deny with input as missing_pab_input
	contains(msg, "AC-3")
	contains(msg, "aws_s3_bucket.bad")
}

test_incomplete_pab_fails if {
	some msg in ac3_aws.deny with input as incomplete_pab_input
	contains(msg, "AC-3")
	contains(msg, "aws_s3_bucket.partial")
}
