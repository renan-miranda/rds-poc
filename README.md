# rds-poc
RDS-POC

 - POC of remote store in Terraform with RDS and EC2 instances

Steps:

  - Create the S3 bucket and DynamoDB lock table for remote store

    On bucket_s3:

    $ terraform init
    $ terraform plan
    $ terraform apply

  - Create the AWS environment using the remote store

    On main:

    - Fill the variables in vars.tf before anything

    $ terraform init
    $ terraform plan
    $ terraform apply

- If runs sucessfull, a file name "addresses.txt" will be created with RDS endpoint, DB name and EC2 public IP
