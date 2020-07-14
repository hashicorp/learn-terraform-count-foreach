# Learn Terraform count and for_each

Learn what Terraform count and for_each are and when to use them.

Follow along with the [Learn guide](https://learn.hashicorp.com/FIXME) at HashiCorp Learn.

## Prerequisites

- AWS Account
- GitHub

### Clone GitHub repository

```sh
git clone ...
```

### Configure AWS credentials

```sh
export AWS_SECRET_KEY_ID=ABC123
export AWS_SECRET_ACCESS_KEY=BCD987
```

## Apply initial configuration

Switch to the tag `01-start`.

```sh
git checkout 01-start
```

This configuration represents a VPC with public and private subnets, a load
balancer, and two EC2 instances representing application servers.

First, initialize the repository.

```sh
terraform init
```

Apply the configuration now.

```sh
terraform apply
```

Respond to the prompt with `yes`.

Once the configuration is complete, you can visit the load balancer URL to
verify that the configuration works as expected.

## Refactor AWS instances using count

Avoid the need to duplicate the `aws_instance` resource block for each instance.

You can check out the tag `02-use-count`, or make the following changes
manually.

```sh
git checkout 02-use-count
```

First, add a variable to `variables.tf` to represent the number of EC2 instances
to provision in each private subnet.

```hcl
variable instances_per_subnet {
  description = "Number of EC2 instances in each private subnet"
  type        = number
  default     = 2
}
```

Then refactor the instance resource blocks in `main.tf`.

Remove the entire resource block for `"aws_instance" "app_b"`.

```hcl
resource "aws_instance" "app_b" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

# ...

}
```

Rename the resource resource `app_a` to `app`.

```hcl
resource "aws_instance" "app_b" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

# ...
```

Add a `count` argument to the `app` resource, and reference it when choosing a subnet.

```hcl
resource "aws_instance" "app" {
  count = var.instances_per_subnet * length(module.vpc.private_subnets)

  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  subnet_id              = module.vpc.private_subnets[count.index % length(module.vpc.private_subnets)]

# ...

}
```

In the `module "elb_http"` block, replace the instance configuration arguments with the following.

```hcl
  number_of_instances = length(aws_instance.app.*)
  instances           = aws_instance.app.*
```

Now run `terraform apply` to see the changes in action.

```bash
$ terraform apply
aws_instance.app_b: Refreshing state... [id=i-00c91186bcbbc06de]
aws_instance.app_a: Refreshing state... [id=i-06dda44c31f56ed97]
data.aws_ami.amazon_linux: Refreshing state... [id=ami-08f3d892de259504d]

# Output truncated...

module.elb_http.module.elb_attachment.aws_elb_attachment.this[3]: Creation complete after 0s [id=elb-terraform-count-foreach-dev-20200713165838359700000003]
module.elb_http.module.elb_attachment.aws_elb_attachment.this[2]: Creation complete after 0s [id=elb-terraform-count-foreach-dev-20200713165838387100000004]

Apply complete! Resources: 8 added, 0 changed, 4 destroyed.

Outputs:

public_dns_name = elb-terraform-count-foreach-dev-2106343869.us-east-1.elb.amazonaws.com
```

Be sure to reply `yes` when prompted.

Now the VPC has a configurable number of instances assigned to the private
subnet and load balancer.

**FIXME**: There's a dependency issue that causes errors. Applying the next step
without destroying resources first results in:

```
Error: Cycle: module.vpc.aws_route_table.private[0] (destroy), module.vpc.aws_subnet.private[1] (destroy), module.vpc.aws_subnet.public[1] (destroy), module.vpc.aws_internet_gateway.this[0] (destroy), module.vpc.aws_route_table.private[1] (destroy), module.vpc["project-beta"].aws_route.public_internet_gateway[0], module.vpc["project-alpha"].aws_route.public_internet_gateway[0], module.vpc.aws_route_table.public[0] (destroy), module.vpc["project-beta"].aws_route_table_association.private[0], module.vpc["project-alpha"].aws_route_table_association.private[1], module.vpc["project-beta"].aws_subnet.private[0], module.vpc["project-alpha"].aws_subnet.private[1], module.vpc["project-alpha"].aws_route_table_association.private[0], module.vpc.aws_subnet.private[0] (destroy), module.vpc["project-alpha"].aws_route_table_association.public[0], module.vpc["project-beta"].aws_route_table_association.public[0], module.vpc["project-alpha"].aws_route_table.public[0], module.vpc["project-beta"].aws_route_table.public[0], module.vpc["project-alpha"].aws_route_table_association.public[1], module.vpc.aws_eip.nat[1] (destroy), module.vpc["project-alpha"].aws_route.private_nat_gateway[1], module.vpc["project-beta"].aws_nat_gateway.this[0], module.vpc["project-alpha"].aws_subnet.public[1], module.vpc["project-alpha"].aws_internet_gateway.this[0], module.vpc["project-beta"].aws_internet_gateway.this[0], module.vpc["project-alpha"].aws_nat_gateway.this[1], module.vpc["project-alpha"].aws_route_table.private[0], module.vpc["project-beta"].aws_route.private_nat_gateway[0], module.vpc.aws_nat_gateway.this[0] (destroy), module.vpc.aws_eip.nat[0] (destroy), module.vpc.local.nat_gateway_ips (expand), module.vpc["project-alpha"].aws_subnet.public[0], module.vpc["project-alpha"].aws_nat_gateway.this[0], module.vpc["project-beta"].aws_route_table.private[0], module.vpc["project-alpha"].aws_route.private_nat_gateway[0], module.vpc.aws_nat_gateway.this[1] (destroy), module.vpc.aws_subnet.public[0] (destroy), module.vpc["project-alpha"].aws_subnet.private[0], module.vpc["project-beta"].aws_subnet.public[0], module.vpc.aws_vpc.this[0] (destroy), module.vpc.local.vpc_id (expand), module.vpc["project-alpha"].aws_route_table.private[1]
```

To work around that, run `terraform destroy` before moving on. This still
results in an error, but the resources are still destroyed.

```
Error: Invalid count argument

  on .terraform/modules/vpc/terraform-aws-vpc-2.44.0/main.tf line 334, in resource "aws_subnet" "public":
 334:   count = var.create_vpc && length(var.public_subnets) > 0 && (false == var.one_nat_gateway_per_az || length(var.public_subnets) >= length(var.azs)) ? length(var.public_subnets) : 0

The "count" value depends on resource attributes that cannot be determined
until apply, so Terraform cannot predict how many instances will be created.
To work around this, use the -target argument to first apply only the
resources that the count depends on.
```

I thought that adding an explicit depends_on to the subnets in the vpc module
would fix this, but I haven't been able to get it to work yet.

**END FIXME**

## Refactor VPC and load balancer configuration using for_each

Next, refactor the VPC and related configuration so that multiple projects can
be deployed at the same time.

You can check out the tag `03-use-for-each` to review the new configuration, or
make the following changes manually.

```sh
git checkout 03-use-for-each
```

Define a variable for project configuration in `variables.tf`.

```hcl
variable project {
  description = "Map of project names to configuration"
  type        = map
  default     = {
    project-alpha = {
      public_subnet_count  = 2,
      private_subnet_count = 2,
      instances_per_subnet = 2,
      instance_type        = "t2.micro",
      environment          = "dev"
    },
    project-beta = {
      public_subnet_count  = 1,
      private_subnet_count = 1,
      instances_per_subnet = 2,
      instance_type        = "t2.nano",
      environment          = "test"
    }
  }
}
```

Since the project variable now includes most of the other options, comment out
or remove these variables from `variables.tf`.

```
# variable project_tag {
#   description = "Value of the 'Project' tag for all resources"
#   type        = string
#   default     = "terraform-count-foreach"
# }

# variable environment {
#   description = "Value of the 'Environment' tag for all resources"
#   type        = string
#   default     = "dev"
# }

# variable public_subnets_per_vpc {
#   description = "Number of public subnets per VPC. Maximum of 16."
#   type        = number
#   default     = 2
# }

# variable private_subnets_per_vpc {
#   description = "Number of private subnets per VPC. Maximum of 16."
#   type        = number
#   default     = 2
# }

# variable instances_per_subnet {
#   description = "Number of EC2 instances in each private subnet"
#   type        = number
#   default     = 2
# }

# variable instance_type {
#   description = "Type of EC2 instance to use"
#   type        = string
#   default     = "t2.micro"
# }
```

Now use `for_each` to iterate over this map when creating the VPC and related
resources. Update the VPC block like the following.

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.44.0"

  for_each = var.project
```

Later in the same block, use `each.value` to refer to the private and public
subnet count for each project in turn.

```
  azs             = data.aws_availability_zones.available.names
  private_subnets = slice(var.private_subnet_cidr_blocks, 0, each.value.private_subnet_count)
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, each.value.public_subnet_count)
```

Update the configuration for the security groups as well.

First the application security group.

```hcl
module "app_security_group" {
  source  = "terraform-aws-modules/security-group/aws//modules/web"
  version = "3.12.0"

  for_each = var.project
  
  name        = "web-server-sg-${each.key}-${each.value.environment}"
  description = "Security group for web-servers with HTTP ports open within VPC"
  vpc_id      = module.vpc[each.key].vpc_id

  ingress_cidr_blocks = module.vpc[each.key].public_subnets_cidr_blocks
}
```

Next, update the load balancer security group.

```hcl
module "lb_security_group" {
  source = "terraform-aws-modules/security-group/aws//modules/web"
  version = "3.12.0"

  for_each = var.project

  name        = "load-balancer-sg-${each.key}-${each.value.environment}"

  description = "Security group for load balancer with HTTP ports open within VPC"
  vpc_id      = module.vpc[each.key].vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}
```

The load balancer configuration will change as well.

```
module "elb_http" {
  source  = "terraform-aws-modules/elb/aws"
  version = "2.4.0"

  for_each = var.project

  # Comply with ELB name restrictions 
  # https://docs.aws.amazon.com/elasticloadbalancing/2012-06-01/APIReference/API_CreateLoadBalancer.html
  name        = substr(replace(join("-", ["lb", each.key, each.value.environment]), "/[^a-zA-Z0-9-]/", ""), 0, 32)
  internal    = false

  security_groups = [module.lb_security_group[each.key].this_security_group_id]
  subnets         = module.vpc[each.key].public_subnets

# ...
```

The instance resource block will also need to be updated. However, it is already
using `count`. You cannot use both `count` and `for_each` in the same block. One
solution is to move `aws_instance` resource into a module, including the `count`
argument, and use `for_each` when referring to the module. The example repo
already includes such a module.

Remove the `resource "aws_instance" "app"` and `data "aws_ami" "amazon_linux"`
blocks from your root module's `main.tf` file, and replace them with a reference
to the `aws-instance` module.

```hcl
module "ec2_instances" {
  source = "./modules/aws-instance"

  for_each = var.project

  instance_count = each.value.instances_per_subnet * length(module.vpc[each.key].private_subnets)
  instance_type = each.value.instance_type
  subnet_ids = module.vpc[each.key].private_subnets[*]
  security_group_ids =  [module.app_security_group[each.key].this_security_group_id]

  project_name = each.key
  environment = each.value.environment
}
```

You will also need to replace the reference to your instances in the `module "elb_http"` block.

```hcl
# ...

  number_of_instances = length(module.ec2_instances[each.key].instance_ids)
  instances           = module.ec2_instances[each.key].instance_ids

# ...
```

Finally, replace the entire contents of `outputs.tf` in your root module with
the following.

```hcl
output public_dns_names {
  description = "Public DNS names of the load balancers for each project"
  value       = { for p in sort(keys(var.project)) : p => module.elb_http[p].this_elb_dns_name }
}
```

Run `terraform init` to initialize the new module.

Run `terraform apply` to apply these changes. Remember to respond to the
confirmation prompt with `yes`.

After verifying that the projects were deployed corrected, run `terraform
destroy` to destroy them. Remember to respond to the confirmation prompt with
`yes`.
