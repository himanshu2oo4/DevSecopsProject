# using terraform vpc module to create one instead of writing from scratch 
module "vpc" {
  source = "terraform-aws-modules/vpc/aws" # through this line the tf will goes to tf registry and search for this module 
  # and download vpc module in .terraform/
  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true # in production go for one nat gateway per az 
  enable_vpn_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # bcoz of this aws will create internet facing load balancers 
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  } # This helps identify subnets suitable for internet-facing Kubernetes load balancers.

  # aws will create internal load balancer here 
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
