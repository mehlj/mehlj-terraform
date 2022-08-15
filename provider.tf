terraform {
  required_providers {
    vsphere = {
      version = "1.15"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "mehlj-state"
    key            = "global/s3/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "mehlj_state_locks"
    encrypt        = true
  }
}

data "aws_secretsmanager_secret" "secrets" {
  arn = "arn:aws:secretsmanager:us-east-1:252267185844:secret:mehlj_lab_creds-j5VElQ"
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.secrets.id
}

provider "vsphere" {
  vsphere_server       = var.vsphere_server
  user                 = var.vsphere_user
  password             = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)["vsphere"]
  allow_unverified_ssl = true
}

provider "aws" {
  region = "us-east-1"
}