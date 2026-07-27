terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  # Local state only — throwaway solo spike, not shared infra.
}

provider "aws" {
  region              = "us-east-1"
  profile             = "sso-tooling"
  allowed_account_ids = ["931932531937"]
}
