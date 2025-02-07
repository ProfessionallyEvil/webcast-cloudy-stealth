terraform {
  # backend "s3" {
  #  bucket = "si-webcast-terraform-state-cloud"
  #  key    = "global/s3_state/terraform.tfstate"
  #  region = "us-east-1"
  # }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  #ts:skip=AWS.S3Bucket.DS.High.1043 Because I am the only one for this account.
  bucket = "si-webcast-terraform-state-cloud"

  # Prevent accidental deletion of this S3 bucket
  # lifecycle {
  #  prevent_destroy = true
  # }

  # Enable versioning so we can see the full revision history of our
  # state files
  versioning {
    enabled = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  # delete bucket
  # force_destroy = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "si-webcast-terraform-state-cloud-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
