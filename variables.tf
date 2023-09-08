variable "aws_region" {
  description = "The AWS region this application will run in"
  default     = "us-west-2"
}

variable "pendo_api_key" {
  description = "Pendo API key"
}

variable "slack_webhook" {
  description = "Webhook for posting to Slack"
}

variable "unique_identifier" {
  description = "A unique identifier for naming resources to avoid name collisions"
  validation {
    condition     = can(regex("^[a-z]{6,10}$", var.unique_identifier))
    error_message = "unique_identifier must be lower case letters only and 6 to 10 characters in length"
  }
}

variable "owner" {
  description = "Your email address"
}
