terraform {
  backend "s3" {
    bucket = "si-webcast-terraform-state-cloud"
    key    = "prod/nessus/terraform.tfstate"
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

module "nessus" {
  source        = "../../../tf_modules/ubuntu_server"
  instance_type = "m5a.xlarge"
  disk_size = 30
  ipv6_ips = 1
  additional_tags = {
    Name = "NessusServer"
    Service = "nessus"
    Type = "scanning"
    NessusScanning = "false"
  }
}

output "public_ip" {
  value = module.nessus.public_ip
}