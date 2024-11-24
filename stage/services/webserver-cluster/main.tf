# Defining the provider and region
provider "aws" {
  region = "us-east-2"
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name  = "naveen-test01-stage"
  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 4
}
