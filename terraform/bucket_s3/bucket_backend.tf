# AWS Provider
provider "aws" {
    version = "~> 1.0"
#    access_key = "${var.access_key}"
#    secret_key = "${var.secret_key}"
    region     = "us-east-1"
}

#######################################################################
# Create a dynamodb table for locking the state file
resource "aws_dynamodb_table" "rds-poc-terraform-state-lock" {
  name = "rds-poc-terraform-state-lock-dynamo"
  hash_key = "LockID"
  read_capacity = 5
  write_capacity = 5
 
  attribute {
    name = "LockID"
    type = "S"
  }
 
  tags {
    Name = "DynamoDB Terraform State Lock Table for RDS-POC"
  }
}
#######################################################################

#######################################################################
# Terraform remote store for state file setup
# Create an S3 bucket to store the state file in
resource "aws_s3_bucket" "rds-poc-remote-state-storage-s3" {
  bucket = "rds-poc-remote-state-storage-s3" 
  versioning {
    enabled = "true"
  }
  force_destroy = true
  tags {
    Name = "S3 remote store for RDS-POC Terraform statefile"
  }      
}
#######################################################################
