resource "aws_subnet" "kubelet" {
  count             = "${length(data.aws_availability_zones.available.names)}"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.main.cidr_block, 5, count.index + 16)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  ipv6_cidr_block   = "${cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index)}"

  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true

  tags {
    Name     = "kuberform-kubelet-${data.aws_availability_zones.available.names[count.index]}"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Role     = "kubelet"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_route_table_association" "kubelet" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.kubelet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "kubelet" {
  name        = "kuberform-kubelet-sg"
  description = "Protects traffic within the Kubernetes Kubelets."
  vpc_id      = "${aws_vpc.main.id}"

  revoke_rules_on_delete = true

  tags {
    Name     = "kuberform-kubelet-sg"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Role     = "kuberform-kubelet"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_security_group_rule" "kubelet-egress" {
  type             = "egress"
  from_port        = -1
  to_port          = -1
  protocol         = -1
  description      = "Outbound Access"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = "${aws_security_group.kubelet.id}"
}

resource "aws_security_group_rule" "kubelet-allow-bastion" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  description = "Bastion Access"

  source_security_group_id = "${aws_security_group.bastion.id}"
  security_group_id        = "${aws_security_group.kubelet.id}"
}

resource "aws_security_group_rule" "kubelet-kubelet-access" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  description = "kubelet Access"

  source_security_group_id = "${aws_security_group.kubelet.id}"
  security_group_id        = "${aws_security_group.kubelet.id}"
}

resource "aws_security_group_rule" "kubelet-network-calico-bgp" {
  type        = "ingress"
  from_port   = 179
  to_port     = 179
  protocol    = "tcp"
  description = "Calico BGP"
  self        = true

  security_group_id = "${aws_security_group.kubelet.id}"
}

resource "aws_security_group_rule" "kubelet-network-flannel-udp" {
  type        = "ingress"
  from_port   = 8285
  to_port     = 8285
  protocol    = "udp"
  description = "Flannel UDP"
  self        = true

  security_group_id = "${aws_security_group.kubelet.id}"
}

resource "aws_security_group_rule" "kubelet-network-flannel-vxlan" {
  type        = "ingress"
  from_port   = 8472
  to_port     = 8472
  protocol    = "udp"
  description = "Flannel VXLAN"
  self        = true

  security_group_id = "${aws_security_group.kubelet.id}"
}

resource "aws_security_group_rule" "kubelet-egress-rds" {
  type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  description = "RDS Access"

  source_security_group_id = "${aws_security_group.rds.id}"
  security_group_id        = "${aws_security_group.kubelet.id}"
}

resource "aws_security_group_rule" "kubelet-egress-elasticache" {
  type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  description = "Elasticache Access"

  source_security_group_id = "${aws_security_group.elasticache.id}"
  security_group_id        = "${aws_security_group.kubelet.id}"
}

resource "aws_security_group_rule" "kubelet-egress-endpoints" {
  type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  description = "Endpoint Access"

  prefix_list_ids = [
    "${aws_vpc_endpoint.dynamodb.prefix_list_id}",
    "${aws_vpc_endpoint.s3.prefix_list_id}",
  ]

  security_group_id = "${aws_security_group.kubelet.id}"
}

resource "aws_security_group_rule" "kubelet-icmp-egress" {
  type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = 1
  description = "ICMP Egress"
  cidr_blocks = ["10.0.0.0/8"]

  security_group_id = "${aws_security_group.kubelet.id}"
}

resource "aws_security_group_rule" "kubelet-icmp-ingress" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = 1
  description = "ICMP Ingress"
  cidr_blocks = ["10.0.0.0/8"]

  security_group_id = "${aws_security_group.kubelet.id}"
}

/*
resource "aws_security_group_rule" "kubelet-allow-alb-ingress" {
  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  description = "ALB Ingress"

  source_security_group_id = "${aws_security_group.alb.id}"
  security_group_id        = "${aws_security_group.kubelet.id}"
}

resource "aws_security_group_rule" "kubelet-allow-alb-egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  description = "ALB Egress"

  source_security_group_id = "${aws_security_group.alb.id}"
  security_group_id        = "${aws_security_group.kubelet.id}"
}
*/

output "subnets_kubelet" {
  value = "${aws_subnet.kubelet.*.id}"
}

output "sg_kubelet" {
  value = "${aws_security_group.kubelet.id}"
}
