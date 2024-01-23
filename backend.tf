terraform {
  backend "s3" {
    bucket         = "volley-terraform-state-bucket"  # Replace with your actual bucket name
    key            = "eks/terraform.tfstate"      # Path to the state file in the bucket
    region         = "us-east-1"                  # Replace with the bucket's region
    dynamodb_table = "terraform-state-lock"       # Replace with your DynamoDB table name
    encrypt        = true
  }
}
