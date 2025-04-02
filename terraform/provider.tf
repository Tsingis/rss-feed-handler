terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    region = "eu-north-1"
    key    = "terraform.tfstate"
  }
}

provider "aws" {
  region = "eu-north-1"
}