terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
  type        = string
}

variable "ubuntu_version" {
  description = "Ubuntu version"
  default     = "22.04"
  type        = string
}

variable "sg_ids" {
  description = "Security group IDs"
  type        = list(string)
  default     = []
}

variable "additional_tags" {
  description = "Additional tags to be added to the instance, i.e. Name, Service, Type"
  type        = map(string)
  default     = {}
}

variable "ipv6_ips" {
  description = "How many IPv6 addresses to assign to the instance"
  type        = number
  default     = 0
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 30
}

data "terraform_remote_state" "account" {
  backend = "s3"
  config = {
    bucket = "si-webcast-terraform-state-cloud"
    key    = "global/account_setup/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/*${var.ubuntu_version}-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

locals {
  tags = merge(
    { OS = "ubuntu" },
    var.additional_tags,
  )
}

resource "aws_instance" "server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = data.terraform_remote_state.account.outputs.prod_keypair
  associate_public_ip_address = true
  subnet_id                   = data.terraform_remote_state.account.outputs.main_network_id
  ipv6_address_count          = var.ipv6_ips
  root_block_device {
    volume_size = var.disk_size
  }


  vpc_security_group_ids = concat(
    [data.terraform_remote_state.account.outputs.sg_allow_all_consultants],
    var.sg_ids,
  )

  tags = local.tags

  lifecycle {
    ignore_changes = [
      ami
    ]
  }
}

output "aws_instance" {
  value = aws_instance.server
}

output "public_ip" {
  value = aws_instance.server.public_ip
}