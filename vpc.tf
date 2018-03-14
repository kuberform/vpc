variable "supernets" {
  type        = "map"
  description = "The various different regional supernets for Kubernetes."

  default = {
    "ap-northeast-1" = "10.0.0.0/12"
    "ap-northeast-2" = "10.16.0.0/12"
    "ap-south-1"     = "10.32.0.0/12"
    "ap-southeast-1" = "10.48.0.0/12"
    "ap-southeast-2" = "10.64.0.0/12"
    "ca-central-1"   = "10.80.0.0/12"
    "eu-central-1"   = "10.96.0.0/12"
    "eu-west-1"      = "10.112.0.0/12"
    "eu-west-2"      = "10.128.0.0/12"
    "eu-west-3"      = "10.144.0.0/12"
    "sa-east-1"      = "10.160.0.0/12"
    "us-east-1"      = "10.176.0.0/12"
    "us-east-2"      = "10.192.0.0/12"
    "us-west-1"      = "10.208.0.0/12"
    "us-west-2"      = "10.224.0.0/12"
  }
}

resource "aws_vpc" "main" {
  cidr_block                       = "${cidrsubnet(var.supernets[data.aws_region.current.name], 4, 0)}"
  instance_tenancy                 = "default"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  enable_classiclink               = false
  enable_classiclink_dns_support   = false
  assign_generated_ipv6_cidr_block = true

  tags {
    Name     = "kuberform-vpc-${data.aws_region.current.name}"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Provider = "https://github.com/kuberform"
  }
}

output "vpc_id" {
  value = "${aws_vpc.main.id}"
}
