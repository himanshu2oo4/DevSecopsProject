
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"                        # use this version for eks module from terraform 

  # EKS Cluster
  name               = var.cluster_name
  kubernetes_version = var.cluster_version     # which kubernetes version this cluster use 

  # Allows access to the EKS API endpoint from outside the VPC  
  # eks cluster have a API server which needs to be communicated from outside so for that we need an endpoint 
  endpoint_public_access = true     # remember this doesn't means your nodes are public 

  # Gives the Terraform creator admin permissions to create your  cluster 
  # enable_cluster_creator_admin_permissions = true # we dont need this if you are using github actions 


  # Allow GitHub Actions IAM role to access Kubernetes API
  access_entries = {
    github_actions = {
      principal_arn = "arn:aws:iam::815802019107:role/GitHubActionsTerraformRole"     # iam role recognized by eks cluster 

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"   # provide k8s administrator access to this 

          access_scope = {
            type = "cluster"         # access provided for the whole cluster not a particular  namespace 
          }
        }
      }
    }
  }



  # EKS Managed Node Group
  eks_managed_node_groups = {
    main = {
      name = "main-node-group"

      
      instance_types = [var.node_ec2_type]

      min_size     = 1
      max_size     = 3
      desired_size = 1
    }
  }

   # -------------------------
  # EKS ADDONS
  # -------------------------

  addons = {
    # provides networking to the pods 
    vpc-cni = {
      before_compute = true   # because networks should be there before getting the ec2 as nodes 
      most_recent    = true
    }

    # implements kubernetes service networking 
    kube-proxy = {
      most_recent = true
    }
    # provides dns inside k8s   frontend calls backend by its service name instead of ip address of pods -> internally it maps it with the IP 
    coredns = {
      most_recent = true
    }

  }

  # Networking
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

