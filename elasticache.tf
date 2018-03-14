resource "aws_subnet" "elasticache" {
  count             = "${length(data.aws_availability_zones.available.names)}"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 48)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"

  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = false

  tags {
    Name     = "kuberform-elasticache-${data.aws_availability_zones.available.names[count.index]}"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Role     = "elasticache"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_route_table_association" "elasticache" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.elasticache.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_security_group" "elasticache" {
  name        = "kuberform-elasticache-sg"
  description = "Protects traffic within the Kubernetes elasticache."
  vpc_id      = "${aws_vpc.main.id}"

  revoke_rules_on_delete = true

  tags {
    Name     = "kuberform-elasticache-sg"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Role     = "kuberform-elasticache"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_security_group_rule" "elasticache-egress" {
  type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  cidr_blocks = ["10.0.0.0/8"]
  description = "Internal Network"

  security_group_id = "${aws_security_group.elasticache.id}"
}

resource "aws_security_group_rule" "elasticache-allow-bastion" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  description = "Bastion Access"

  source_security_group_id = "${aws_security_group.bastion.id}"
  security_group_id        = "${aws_security_group.elasticache.id}"
}

resource "aws_security_group_rule" "elasticache-allow-kubelet-redis" {
  type        = "ingress"
  from_port   = 6379
  to_port     = 6379
  protocol    = "tcp"
  description = "Kubelet Redis Access"

  source_security_group_id = "${aws_security_group.kubelet.id}"
  security_group_id        = "${aws_security_group.elasticache.id}"
}

resource "aws_security_group_rule" "elasticache-allow-controller-redis" {
  type        = "ingress"
  from_port   = 6379
  to_port     = 6379
  protocol    = "tcp"
  description = "Controller Redis Access"

  source_security_group_id = "${aws_security_group.controller.id}"
  security_group_id        = "${aws_security_group.elasticache.id}"
}

resource "aws_security_group_rule" "elasticache-allow-kubelet-memcached" {
  type        = "ingress"
  from_port   = 11211
  to_port     = 11211
  protocol    = "tcp"
  description = "Kubelet Memcached Access"

  source_security_group_id = "${aws_security_group.kubelet.id}"
  security_group_id        = "${aws_security_group.elasticache.id}"
}

resource "aws_security_group_rule" "elasticache-allow-controller-memcached" {
  type        = "ingress"
  from_port   = 11211
  to_port     = 11211
  protocol    = "tcp"
  description = "Controller Memcached Access"

  source_security_group_id = "${aws_security_group.controller.id}"
  security_group_id        = "${aws_security_group.elasticache.id}"
}

resource "aws_security_group_rule" "elasticache-icmp-egress" {
  type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = 1
  description = "ICMP Egress"
  cidr_blocks = ["10.0.0.0/8"]

  security_group_id = "${aws_security_group.elasticache.id}"
}

resource "aws_security_group_rule" "elasticache-icmp-ingress" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = 1
  description = "ICMP Ingress"
  cidr_blocks = ["10.0.0.0/8"]

  security_group_id = "${aws_security_group.elasticache.id}"
}

output "subnets_elasticache" {
  value = "${aws_subnet.elasticache.*.id}"
}

output "sg_elasticache" {
  value = "${aws_security_group.elasticache.id}"
}
