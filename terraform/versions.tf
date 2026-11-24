terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Hybrid-Hub-Spoke-Landing-Zone"
      Environment = var.environment
      ManagedBy   = "Terraform-Network-Blueprint"
      Owner       = var.cost_center
    }
  }
}
