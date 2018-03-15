resource "aws_subnet" "rds" {
  count             = "${length(data.aws_availability_zones.available.names)}"
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 32)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"

  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = false

  tags {
    Name     = "kuberform-rds-${data.aws_availability_zones.available.names[count.index]}"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Role     = "rds"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_route_table_association" "rds" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.rds.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "rds" {
  name        = "kuberform-rds-sg"
  description = "Protects traffic within the Kubernetes RDS."
  vpc_id      = "${aws_vpc.main.id}"

  revoke_rules_on_delete = true

  tags {
    Name     = "kuberform-rds-sg"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Role     = "kuberform-rds"
    Provider = "https://github.com/kuberform"
  }
}

resource "aws_security_group_rule" "rds-egress" {
  type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  cidr_blocks = ["10.0.0.0/8"]
  description = "Internal Network"

  security_group_id = "${aws_security_group.rds.id}"
}

resource "aws_security_group_rule" "rds-allow-bastion" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = -1
  description = "Bastion Access"

  source_security_group_id = "${aws_security_group.bastion.id}"
  security_group_id        = "${aws_security_group.rds.id}"
}

resource "aws_security_group_rule" "rds-allow-kubelet-mysql" {
  type        = "ingress"
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  description = "Kubelet MySQL Access"

  source_security_group_id = "${aws_security_group.kubelet.id}"
  security_group_id        = "${aws_security_group.rds.id}"
}

resource "aws_security_group_rule" "rds-allow-controller-mysql" {
  type        = "ingress"
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  description = "Controller MySQL Access"

  source_security_group_id = "${aws_security_group.controller.id}"
  security_group_id        = "${aws_security_group.rds.id}"
}

resource "aws_security_group_rule" "rds-allow-kubelet-pgsql" {
  type        = "ingress"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  description = "Kubelet PgSQL Access"

  source_security_group_id = "${aws_security_group.kubelet.id}"
  security_group_id        = "${aws_security_group.rds.id}"
}

resource "aws_security_group_rule" "rds-allow-controller-pgsql" {
  type        = "ingress"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  description = "Controller PgSQL Access"

  source_security_group_id = "${aws_security_group.controller.id}"
  security_group_id        = "${aws_security_group.rds.id}"
}

resource "aws_security_group_rule" "rds-icmp-egress" {
  type        = "egress"
  from_port   = -1
  to_port     = -1
  protocol    = 1
  description = "ICMP Egress"
  cidr_blocks = ["10.0.0.0/8"]

  security_group_id = "${aws_security_group.rds.id}"
}

resource "aws_security_group_rule" "rds-icmp-ingress" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = 1
  description = "ICMP Ingress"
  cidr_blocks = ["10.0.0.0/8"]

  security_group_id = "${aws_security_group.rds.id}"
}

output "subnets_rds" {
  value = "${aws_subnet.rds.*.id}"
}

output "sg_rds" {
  value = "${aws_security_group.rds.id}"
}
