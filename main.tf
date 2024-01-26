locals {
  notifyapp_fname    = "${var.unique_identifier}_lambda_notifyapp"
  notifyapp_loggroup = "/aws/lambda/${local.notifyapp_fname}"
}

provider "aws" {
  region = var.aws_region
}

provider "archive" {}
