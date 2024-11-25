terraform {
  required_version = ">=v1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.77.0"
    }
  }
  backend "s3" {
    bucket = "terraform-state-devops-test"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "webapp_image" {
  type = string
  # for testing
  default = "nginx:1.27-alpine"
}

variable "webapp_port" {
  type    = number
  default = 80
}

variable "webapp_healthcheck_path" {
  type    = string
  default = "/"
}
