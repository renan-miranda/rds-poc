# AWS Provider
provider "aws" {
  version = "~> 1.0"
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
# Create a random id to ensure that s3 bucket name will be unique
resource "random_id" "remote_s3_bucket" {
  prefix = "rds-poc-remote-state-"
  byte_length = 4
}
#######################################################################

#######################################################################
# Terraform remote store for state file setup
# Create an S3 bucket to store the state file in
resource "aws_s3_bucket" "rds-poc-remote-state-storage-s3" {
  bucket = "${random_id.remote_s3_bucket.dec}" 
  versioning {
    enabled = "true"
  }
  force_destroy = true
  tags {
    Name = "S3 remote store for RDS-POC Terraform statefile"
  }      
}
#######################################################################

#######################################################################
# File to store the S3 bucket name
resource "local_file" "bucket_name" {
    content  = "REMOTE_BUCKET_NAME=${aws_s3_bucket.rds-poc-remote-state-storage-s3.bucket}"
    filename = "${path.module}/../resources/remote_s3_bucket.sh"
}
#######################################################################
