terraform {

  backend "s3" {

    bucket = "himanshu-terraform-state-815802019107"

    key = "eks/terraform.tfstate"

    region = "ap-south-1"

    encrypt = true

    use_lockfile = true
  }
}