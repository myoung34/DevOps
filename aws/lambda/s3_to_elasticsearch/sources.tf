variable "region" {
  default = "us-east-1"
}

provider "aws" {
  version = "1.14"
  region  = "${var.region}"
}
