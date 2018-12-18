#######################################################################
# AWS Provider
provider "aws" {
    version = "~> 1.0"
    region     = "us-east-1"
}
#######################################################################

#######################################################################
# Backend creation to remote store the state file
terraform {
  backend "s3" {
    encrypt = "true"
    region = "us-east-1"
    key = ".terraform/terraform.tfstate"
  }
}
#######################################################################

#######################################################################
# Creates a key pair to connect in your EC2 instances
resource "aws_key_pair" "auth" {
 key_name = "${var.ssh_key_name}"
 public_key = "${file(var.ssh_public_key_path)}"
}
#######################################################################

#######################################################################
# VPC configuration
# Create VPC
resource "aws_vpc" "rds-poc-vpc" {
  cidr_block  = "172.32.0.0/16"
  enable_dns_hostnames = "true"

  tags {
    Name = "rds-poc-vpc"
  }
}

# Create Internet Gateway for VPC
resource "aws_internet_gateway" "rds-poc-igw" {
  vpc_id = "${aws_vpc.rds-poc-vpc.id}"

  tags {
    Name = "rds-poc-igw"
  }
}

# Default Route Table for VPC
# Attaching IGW created on last step
resource "aws_default_route_table" "rds-poc-default-rt" {
  depends_on = ["aws_internet_gateway.rds-poc-igw"]
  default_route_table_id = "${aws_vpc.rds-poc-vpc.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.rds-poc-igw.id}"
  }

  tags {
    Name = "rds-poc-default-rt"
  }
}


# Create public subnet for EC2 instance
resource "aws_subnet" "subnet-rds-poc-ec2" {
  vpc_id     = "${aws_vpc.rds-poc-vpc.id}"
  cidr_block = "172.32.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = "true"
  
  tags {
    Name = "subnet-rds-poc-ec2"
  }
}

# Create 1st private subnet for EC2 instance
resource "aws_subnet" "subnet-rds-poc-postgres1" {
  vpc_id     = "${aws_vpc.rds-poc-vpc.id}"
  cidr_block = "172.32.1.0/24"
  availability_zone = "us-east-1a"
  
  tags {
    Name = "subnet-rds-poc-postgres1"
  }
}

# Create 2nd private subnet for EC2 instance
resource "aws_subnet" "subnet-rds-poc-postgres2" {
  vpc_id     = "${aws_vpc.rds-poc-vpc.id}"
  cidr_block = "172.32.2.0/24"
  availability_zone = "us-east-1b"
  
  tags {
    Name = "subnet-rds-poc-postgres2"
  }
}

# NACL for VPC
resource "aws_default_network_acl" "rds-poc-default-nacl" {
  default_network_acl_id = "${aws_vpc.rds-poc-vpc.default_network_acl_id}"

  # ALL access to anywhere
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  # ALL access to anywhere
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags {
    Name = "rds-poc-default-nacl"
  }
}

# Change the route table for subnet
resource "aws_route_table_association" "subnet-public-rt" {
  subnet_id      = "${aws_subnet.subnet-rds-poc-ec2.id}"
  route_table_id = "${aws_default_route_table.rds-poc-default-rt.id}"
}

# Security Group for RDS instances
resource "aws_security_group" "rds-poc-postgres-sg" {
  name = "rds-poc-postgres-sg"

  description = "SG for postgres servers for RDS-POC"
  vpc_id = "${aws_vpc.rds-poc-vpc.id}"

  # Only postgres port allowed in inbound traffic from ec2 SG
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = ["${aws_security_group.rds-poc-ec2-sg.id}"]
  }

  # Allow all outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for EC2 instances
resource "aws_security_group" "rds-poc-ec2-sg" {
  name = "rds-poc-ec2-sg"

  description = "SG for EC2 instances for RDS-POC"
  vpc_id = "${aws_vpc.rds-poc-vpc.id}"

  # Only HTTP port allowed in inbound traffic
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Only HTTP port allowed in inbound traffic
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  # Allow all outbound traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#######################################################################

#######################################################################
# DB subnet group
resource "aws_db_subnet_group" "rds-poc-db-subnet" {
  name = "rds-poc-db-subnet"
  description = "DB subnet group for RDS-POC"
  subnet_ids = ["${aws_subnet.subnet-rds-poc-postgres1.id}","${aws_subnet.subnet-rds-poc-postgres2.id}"]
}

# RDS Instance Creation
resource "aws_db_instance" "postgres_rds_instance_01" {
  engine                   = "postgres"
  engine_version           = "10.4"
  instance_class           = "db.t2.micro"
  multi_az                 = false
  storage_type             = "gp2"
  allocated_storage        = 5
  db_subnet_group_name     = "${aws_db_subnet_group.rds-poc-db-subnet.id}"
  identifier               = "postgres-rds-instance-01"
  username                 = "${var.postgre_user}"
  password                 = "${var.postgre_passwd}"
  publicly_accessible      = false
  vpc_security_group_ids   = ["${aws_security_group.rds-poc-postgres-sg.id}"]
  name                     = "${var.postgre_db_name}"
  port                     = 5432
  backup_retention_period  = 7
  skip_final_snapshot      = "true"
}
#######################################################################

#######################################################################
# Creates a key pair to connect in your EC2 instances
# EC2 instance
resource "aws_instance" "rds-poc-ec2" {
  ami = "${data.aws_ami.aws-linux2.id}"
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.subnet-rds-poc-ec2.id}"
  security_groups             = ["${aws_security_group.rds-poc-ec2-sg.id}"]
  associate_public_ip_address = "true"
  key_name                    = "${aws_key_pair.auth.key_name}"
  user_data_base64            = "${var.user_data_base64}"
  
  root_block_device {
    volume_type = "gp2"
    volume_size = "80"
    delete_on_termination = "true"
  }

  tags {
    Name = "rds-poc-ec2"
  }
}
#######################################################################

#######################################################################
# File with DB and EC2 addresses
resource "local_file" "env_aws" {
  filename = "./addresses.txt"

  content = <<-EOF
RDS_PUBLIC_LB=${aws_db_instance.postgres_rds_instance_01.endpoint}
RDS_DB_NAME=${aws_db_instance.postgres_rds_instance_01.name}

EC2_PUBLIC_IP=${aws_instance.rds-poc-ec2.public_ip}
 EOF
}
#######################################################################
