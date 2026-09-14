# remember terraform block can handle its own configuration as well as provider configuration as well 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

