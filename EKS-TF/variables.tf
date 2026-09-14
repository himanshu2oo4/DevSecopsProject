variable "aws_region" {
  type        = string
  default     = "ap-south-1"
  description = "region to deploy your eks cluster "
}

variable "cluster_name" {
  description = "Name of the eks cluster"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC "
  type        = string
}

variable "availability_zones" {
  description = "Az for the vpc "
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR blocks for the public subnets"
  type        = list(string) # a list containing strings
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}


variable "node_ec2_type" {
  description = "describes the type of ec2 you want as your node"
  type = string 
}