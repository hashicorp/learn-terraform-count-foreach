output "public_dns_names" {
  description = "Public DNS names of the load balancers for each project"
  value       = { for p in sort(keys(var.project)) : p => module.elb_http[p].this_elb_dns_name }
}
