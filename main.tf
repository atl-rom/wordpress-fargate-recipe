# main.tf
terraform {
  required_version = "~> 0.14.7"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "atl-rom"
    workspaces {
      name = "tfc"
    }
  }
}
provider "aws" {
  region = var.server_region
}

