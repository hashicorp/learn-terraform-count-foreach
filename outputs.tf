output public_dns_names {
  description = "Public DNS names of the load balancers for each project"
  value       = { for p in sort(keys(var.project)) : p => module.elb_http[p].this_elb_dns_name }
}

output vpc_arns {
  description = "ARNs of the vpcs for each project"
  value       = { for p in sort(keys(var.project)) : p => module.vpc[p].vpc_arn }
}

output instance_ids {
  description = "IDs of EC2 instances"
  value       = { for p in sort(keys(var.project)) : p => module.ec2_instances[p].instance_ids }
}
