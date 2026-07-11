terraform {
  backend "s3" {
    key     = "eks/dev/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
