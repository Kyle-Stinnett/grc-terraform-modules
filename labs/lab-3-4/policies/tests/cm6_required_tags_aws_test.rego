# policies/tests/cm6_required_tags_aws_test.rego
package compliance.cm6_aws_test

import rego.v1
import data.compliance.cm6_aws

complete := {"planned_values": {"root_module": {"resources": [{
	"address": "aws_s3_bucket.good",
	"type": "aws_s3_bucket",
	"values": {"tags_all": {
		"Project": "x",
		"Environment": "dev",
		"ManagedBy": "terraform",
		"ComplianceScope": "cge-p-lab",
	}},
}]}}}

missing := {"planned_values": {"root_module": {"resources": [{
	"address": "aws_s3_bucket.bad",
	"type": "aws_s3_bucket",
	"values": {"tags": {"Project": "x"}},
}]}}}

no_tags := {"planned_values": {"root_module": {"resources": [{
	"address": "aws_s3_bucket.naked",
	"type": "aws_s3_bucket",
	"values": {},
}]}}}

test_complete_passes if { count(cm6_aws.deny) == 0 with input as complete }
test_partial_fails if { some msg in cm6_aws.deny with input as missing; contains(msg, "CM-6") }
test_no_tags_fail if { some msg in cm6_aws.deny with input as no_tags; contains(msg, "CM-6") }
