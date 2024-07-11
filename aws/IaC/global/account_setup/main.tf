terraform {
  backend "s3" {
    bucket = "si-webcast-terraform-state-cloud"
    key    = "global/account_setup/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = local.region
}

locals {
  region = "us-east-1"
}

resource "aws_key_pair" "deployer" {
  key_name   = "prod-key"
  public_key = file(pathexpand("~/.ssh/id_rsa.pub"))
}

data "http" "current_ip" {
  url = "https://api.ipify.org/?format=json"
}

resource "aws_ec2_managed_prefix_list" "consultants_list" {
  name = "Consultants-IPs"
  address_family = "IPv4"
  max_entries = 20

  entry {
    cidr = "${jsondecode(data.http.current_ip.body).ip}/32"
    description = "personal home"
  }

}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "main"
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.104.0/24", "10.0.105.0/24", "10.0.106.0/24"]

  enable_ipv6 = true

  enable_nat_gateway = false
  single_nat_gateway = true
  enable_dns_hostnames = true
  public_subnet_ipv6_prefixes   = [0, 1, 3]
  create_database_subnet_group = true
  create_database_subnet_route_table = true
  create_database_internet_gateway_route = true

  # public_subnet_tags = {
  #   Name = "overridden-name-public"
  # }

  database_subnet_group_name = "offensive-database-subnet-group"
  # database_subnet_assign_ipv6_address_on_creation = false
  # database_subnet_enable_dns64 = false
  database_subnet_ipv6_prefixes = [5,7,9]
  private_subnet_ipv6_prefixes = [2,4,6]
  database_subnet_names = [ "offensive-dbs-1", "offensive-dbs-2", "offensive-dbs-3" ]

  # tags = {
  #   Owner       = "user"
  #   Environment = "dev"
  # }

  vpc_tags = {
    Name = "default-offensive-vpc"
  }
  
}

resource "aws_security_group" "allow_db_access" {
  name = "allow_db_access"
  description = "An empty security group to allow access to the database, anything with this SG will be able to access the database"
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "allow_db_access"
  }
}

resource "aws_security_group" "allow_all_consultants" {
  name = "allow_known"
  description = "allowing known things in"
  vpc_id = module.vpc.vpc_id
  tags = {
    Name = "allow_known"
  }
}

resource "aws_security_group_rule" "allow_all_consultants_rule" {
  type = "ingress"
  description = "all consultants"
  from_port = 0
  to_port = 0
  protocol = "-1"
  prefix_list_ids = [aws_ec2_managed_prefix_list.consultants_list.id]
  security_group_id = aws_security_group.allow_all_consultants.id
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  description = "allow all outbound"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = aws_security_group.allow_all_consultants.id
}

output "prod_keypair" {
  value = aws_key_pair.deployer.key_name
}

output "consultants_prefix_list_id" {
  value = aws_ec2_managed_prefix_list.consultants_list.id
}

output "main_network_id" {
  value = module.vpc.public_subnets[0]
}

output "main_vpc_id" {
  value = module.vpc.vpc_id
}

output "db_subnet_group_name" {
  value = module.vpc.database_subnet_group_name
}

output "sg_allow_all_consultants" {
  value = aws_security_group.allow_all_consultants.id
}

output "sg_allow_db_access" {
  value = aws_security_group.allow_db_access.id
}

output "main_vpc_azs" {
  value = module.vpc.azs
}