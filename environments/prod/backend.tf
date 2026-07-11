terraform {
  backend "s3" {
    key     = "eks/prod/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
