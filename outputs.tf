output public_dns_name {
  description = "Public DNS name of load balancer"
  value       = module.elb_http.this_elb_dns_name
}
