terraform {
  backend "s3" {
    bucket = "si-webcast-terraform-state-cloud"
    key    = "prod/bruteforce/terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

module "bruteforcing" {
  source        = "../../../tf_modules/kali_server"
  instance_type = "c5a.xlarge"
  ipv6_ips = 1
  additional_tags = {
    Name = "Bruteforce",
    Type = "bruteforcing"
  }
}

output "public_ip" {
  value = module.bruteforcing.public_ip
}