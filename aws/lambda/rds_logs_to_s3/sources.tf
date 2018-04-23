variable "region" {
  default = "us-east-1"
}

provider "aws" {
  version = "1.14"
  region  = "${var.region}"
}

data "terraform_remote_state" "somebucket" {
  backend = "s3"

  config {
    bucket = "changeme"
    key    = "setme"
    region = "us-east-1"
  }
}


