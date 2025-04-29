terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "eks_cluster/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks" # Optional but good for concurrency
  }
}
