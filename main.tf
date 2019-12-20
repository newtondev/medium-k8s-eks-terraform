provider "aws" {
  version = "~> 2.7"
  region  = var.aws_region
  profile = "default"
}

terraform {
  required_version = ">= 0.12.1"
}

provider "template" {
  version = "~> 2.1"
}

data "aws_caller_identity" "current" {}
