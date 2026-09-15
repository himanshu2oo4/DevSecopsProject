aws_region = "ap-south-1"

cluster_name = "tetris-eks-cluster"

vpc_cidr = "10.0.0.0/16"

availability_zones = ["ap-south-1a", "ap-south-1b"]

private_subnets = [
  "10.0.11.0/24",
  "10.0.12.0/24"
]

public_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

cluster_version = "1.36"

node_ec2_type = "c7i-flex.large"