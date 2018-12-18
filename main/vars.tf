# Key name for ssh access on EC2 instance
variable "ssh_key_name" { 
  default = ""
}

# Path where ssh public key is stored
variable "ssh_public_key_path" {
  default = ""
}

# Name of PostgreSQL database.
variable "postgre_db_name" {
  default = ""
}

# User of PostgreSQL instance.
variable "postgre_user" {
  default = ""
}

# Password for user on PostgreSQL instance.
variable "postgre_passwd" {
  default = ""
}

# User data in base64 to start EC2 instance
variable "user_data_base64" {
  default = ""
}

data "aws_ami" "aws-linux2" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
