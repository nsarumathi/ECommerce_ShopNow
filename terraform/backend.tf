terraform {
  backend "s3" {
    bucket       = "shopnow-terraform-state1"
    key          = "prod/terraform.tfstate"
    region       = "ap-south-2"
    encrypt      = true
    use_lockfile = true
  }
}
