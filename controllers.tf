resource "aws_subnet" "controller" {
  count             = "${length(data.aws_availability_zones.available.names)}"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"

  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = false

  tags {
    Name     = "kuberform-controller-${data.aws_availability_zones.available.names[count.index]}"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Role     = "kuberform-controller"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_route_table_association" "controller" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.controller.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "controller" {
  name        = "kuberform-controller-sg"
  description = "Protects traffic within the Kubernetes controllers."
  vpc_id      = "${aws_vpc.main.id}"

  revoke_rules_on_delete = true

  tags {
    Name     = "kuberform-controller-sg"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Role     = "kuberform-controller"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_security_group_rule" "controller-egress" {
  type             = "egress"
  from_port        = -1
  to_port          = -1
  protocol         = -1
  description      = "Outbound Access"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "controller-internal-egress" {
  type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  description = "Internal Access"
  self        = true

  security_group_id = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "controller-https-ingress" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  description = "HTTPs Access"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "controller-https-alt-ingress" {
  type        = "ingress"
  from_port   = 6443
  to_port     = 6443
  protocol    = "tcp"
  description = "HTTPs Access"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "controller-etcd-ingress" {
  type        = "ingress"
  from_port   = 2379
  to_port     = 2380
  protocol    = "tcp"
  description = "ETCD Access"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "controller-internal-ingress" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  description = "Internal Access"
  self        = true

  security_group_id = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "controller-allow-bastion" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  description = "Bastion Access"

  source_security_group_id = "${aws_security_group.bastion.id}"
  security_group_id        = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "controller-egress-rds" {
  type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  description = "RDS Access"

  source_security_group_id = "${aws_security_group.rds.id}"
  security_group_id        = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "controller-egress-elasticache" {
  type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  description = "Elasticache Access"

  source_security_group_id = "${aws_security_group.elasticache.id}"
  security_group_id        = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "controller-egress-endpoints" {
  type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  description = "Endpoint Access"

  prefix_list_ids = [
    "${aws_vpc_endpoint.dynamodb.prefix_list_id}",
    "${aws_vpc_endpoint.s3.prefix_list_id}",
  ]

  security_group_id = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "controller-icmp-egress" {
  type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = 1
  description = "ICMP Egress"
  cidr_blocks = ["10.0.0.0/8"]

  security_group_id = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "controller-icmp-ingress" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = 1
  description = "ICMP Ingress"
  cidr_blocks = ["10.0.0.0/8"]

  security_group_id = "${aws_security_group.controller.id}"
}

/*
resource "aws_security_group_rule" "controller-allow-alb-ingress" {
  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  description = "ALB Ingress"

  source_security_group_id = "${aws_security_group.alb.id}"
  security_group_id        = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "controller-allow-alb-egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  description = "ALB Egress"

  source_security_group_id = "${aws_security_group.alb.id}"
  security_group_id        = "${aws_security_group.controller.id}"
}
*/

output "subnets_controller" {
  value = "${aws_subnet.controller.*.id}"
}

output "sg_controller" {
  value = "${aws_security_group.controller.id}"
}
