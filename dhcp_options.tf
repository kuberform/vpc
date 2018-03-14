resource "aws_vpc_dhcp_options" "main" {
  domain_name         = "${data.aws_region.current.name}.k8s.audios.cloud"
  domain_name_servers = ["AmazonProvidedDNS"]
  ntp_servers         = ["169.254.169.123"]

  tags {
    Name     = "kuberform-dhcp-${data.aws_region.current.name}"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_vpc_dhcp_options_association" "main" {
  vpc_id          = "${aws_vpc.main.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.main.id}"
}
