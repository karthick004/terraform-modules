terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "eks_cluster/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-locks" # Optional but good for concurrency
  }
}
