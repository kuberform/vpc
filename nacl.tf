resource "aws_default_network_acl" "default" {
  default_network_acl_id = "${aws_vpc.main.default_network_acl_id}"

  subnet_ids = ["${concat(
    aws_subnet.bastion.*.id,
    aws_subnet.controller.*.id,
    aws_subnet.elasticache.*.id,
    aws_subnet.kubelet.*.id,
    aws_subnet.rds.*.id,
  )}"]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol        = -1
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol        = -1
    rule_no         = 101
    action          = "allow"
    ipv6_cidr_block = "::/0"
    from_port       = 0
    to_port         = 0
  }

  tags {
    Name    = "kuberform-def-nacl"
    Owner   = "infrastructure"
    Billing = "costcenter"
    Role    = "network-acl"
  }
}
