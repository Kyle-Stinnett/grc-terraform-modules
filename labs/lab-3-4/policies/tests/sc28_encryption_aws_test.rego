# policies/tests/sc28_encryption_aws_test.rego
package compliance.sc28_aws_test

import rego.v1
import data.compliance.sc28_aws

compliant_input := {"configuration": {"root_module": {"resources": [
	{"type": "aws_s3_bucket", "name": "primary"},
	{
		"type": "aws_s3_bucket_server_side_encryption_configuration",
		"name": "primary",
		"expressions": {"bucket": {"references": ["aws_s3_bucket.primary.id", "aws_s3_bucket.primary"]}},
	},
]}}}

noncompliant_input := {"configuration": {"root_module": {"resources": [
	{"type": "aws_s3_bucket", "name": "bad"},
]}}}

test_compliant_passes if { count(sc28_aws.deny) == 0 with input as compliant_input }

test_noncompliant_fails if {
	some msg in sc28_aws.deny with input as noncompliant_input
	contains(msg, "SC-28")
	contains(msg, "aws_s3_bucket.bad")
}
