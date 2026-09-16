terraform {

  backend "s3" {

    bucket = "your-backend-bucket-name"

    key = "eks/terraform.tfstate"

    region = "ap-south-1"

    encrypt = true

    use_lockfile = true
  }
}
