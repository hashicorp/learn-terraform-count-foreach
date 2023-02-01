# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output instance_ids {
  description = "IDs of EC2 instances"
  value       = aws_instance.app.*.id
}
