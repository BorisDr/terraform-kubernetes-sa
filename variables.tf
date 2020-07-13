data "aws_caller_identity" "current" {}

variable "cluster_name" {
  type = string
}

variable "stack" {
  type = string
}

variable "service" {
  type = string
}

variable "region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "namespace" {
  type = string
}

variable "tags" {
  type    = map
  default = {}
}

data "terraform_remote_state" "infra_staging" {
  backend = "remote"
  config = {
    organization = "pluto-tv"
    # this intentionally has an `=` see the Note on the remote_state provider page
    workspaces = {
      name = "infra-staging"
    }
  }
}
