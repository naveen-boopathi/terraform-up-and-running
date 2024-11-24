provider "aws" {
  region = "us-east-2"
}

resource "aws_db_instance" "db-instance" {
  identifier_prefix   = "db-instance-terraform-up-and-running"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t2.micro"
  skip_final_snapshot = true
  db_name             = "naveen_terraform"

  username = var.db_username
  password = var.db_password
}


# terraform {
#   backend "s3" {
#     bucket = "naveen-test01-terraform-state-file"
#     key = "stage/data-stores/mysql/terraform.tfstate"
#     region = "us-east-2"

#     dynamodb_table = "naveen-test01-terraform-up-and-running-locks"
#     encrypt = true
#   }
# }
