terraform {
  backend "s3" {
    key     = "eks/stg/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
