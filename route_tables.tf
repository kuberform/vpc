resource "aws_vpn_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name     = "kuberform-route-private"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name     = "kuberform-route-default"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_eip" "nat-gw" {
  vpc = true

  tags {
    Name     = "kuberform-natgw-eip"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = "${aws_eip.nat-gw.id}"
  subnet_id     = "${aws_subnet.bastion.*.id[0]}"

  tags {
    Name     = "kuberform-nat-gw"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_egress_only_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = "${aws_vpc.main.id}"
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  route_table_ids = [
    "${aws_default_route_table.default.id}",
    "${aws_route_table.public.id}",
    "${aws_route_table.private.id}",
  ]
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = "${aws_vpc.main.id}"
  service_name = "com.amazonaws.${data.aws_region.current.name}.dynamodb"

  route_table_ids = [
    "${aws_default_route_table.default.id}",
    "${aws_route_table.public.id}",
    "${aws_route_table.private.id}",
  ]
}

resource "aws_route" "igw-public-ipv4" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.main.id}"
}

resource "aws_route" "igw-public-ipv6" {
  route_table_id              = "${aws_route_table.public.id}"
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = "${aws_internet_gateway.main.id}"
}

resource "aws_route" "igw-default-ipv4" {
  route_table_id         = "${aws_default_route_table.default.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.main.id}"
}

resource "aws_route" "igw-default-ipv6" {
  route_table_id              = "${aws_default_route_table.default.id}"
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = "${aws_internet_gateway.main.id}"
}

resource "aws_route" "eig-private-ipv4" {
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.nat-gw.id}"
}

resource "aws_route" "eig-private-ipv6" {
  route_table_id              = "${aws_route_table.private.id}"
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = "${aws_egress_only_internet_gateway.main.id}"
}

resource "aws_default_route_table" "default" {
  default_route_table_id = "${aws_vpc.main.default_route_table_id}"

  tags {
    Name     = "kuberform-route-default"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  propagating_vgws = [
    "${aws_vpn_gateway.main.id}",
  ]

  tags {
    Name     = "kuberform-route-public"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.main.id}"

  propagating_vgws = [
    "${aws_vpn_gateway.main.id}",
  ]

  tags {
    Name     = "kuberform-route-private"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Provider = "https://github.com/kuberform"
  }
}
