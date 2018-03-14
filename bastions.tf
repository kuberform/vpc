resource "aws_subnet" "bastion" {
  count             = "${length(data.aws_availability_zones.available.names)}"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 16)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  ipv6_cidr_block   = "${cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index + 16)}"

  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true

  tags {
    Name     = "kuberform-bastion-${data.aws_availability_zones.available.names[count.index]}"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Role     = "bastion"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_route_table_association" "bastion" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.bastion.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "bastion" {
  name        = "kuberform-bastion-sg"
  description = "Protects traffic within the Kubernetes bastions."
  vpc_id      = "${aws_vpc.main.id}"

  revoke_rules_on_delete = true

  tags {
    Name     = "kuberform-bastion-sg"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Role     = "kuberform-bastion"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_security_group_rule" "bastion-egress" {
  type             = "egress"
  from_port        = -1
  to_port          = -1
  protocol         = -1
  description      = "Outbound Access"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "bastion-internal-egress" {
  type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  description = "Internal Access"
  self        = true

  security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "bastion-internal-ingress" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  description = "Internal Access"
  self        = true

  security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "bastion-egress-endpoints" {
  type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  description = "Endpoint Access"

  prefix_list_ids = [
    "${aws_vpc_endpoint.dynamodb.prefix_list_id}",
    "${aws_vpc_endpoint.s3.prefix_list_id}",
  ]

  security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "bastion-icmp-egress" {
  type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = 1
  description = "ICMP Egress"
  cidr_blocks = ["10.0.0.0/8"]

  security_group_id = "${aws_security_group.bastion.id}"
}

resource "aws_security_group_rule" "bastion-icmp-ingress" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = 1
  description = "ICMP Ingress"
  cidr_blocks = ["10.0.0.0/8"]

  security_group_id = "${aws_security_group.bastion.id}"
}

output "subnets_bastion" {
  value = "${aws_subnet.bastion.*.id}"
}

output "sg_bastion" {
  value = "${aws_security_group.bastion.id}"
}
