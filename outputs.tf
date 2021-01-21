output "public_dns_name" {
  description = "Public DNS name of load balancer"
  value       = module.elb_http.this_elb_dns_name
}

output "vpc_arn" {
  description = "ARN of the vpc"
  value       = module.vpc.vpc_arn
}

output "instance_ids" {
  description = "IDs of EC2 instances"
  value       = [aws_instance.app_a.id, aws_instance.app_b.id]
}
