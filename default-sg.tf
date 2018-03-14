resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.main.id}"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = -1
    security_groups = ["${aws_security_group.bastion.id}"]
    description     = "Bastion Access"
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = 1
    cidr_blocks = ["0.0.0.0/0"]
    description = "ICMP Ingress"
  }

  egress {
    from_port   = -1
    to_port     = -1
    protocol    = 1
    cidr_blocks = ["0.0.0.0/0"]
    description = "ICMP Egress"
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Outbound Access"
  }

  tags {
    Name     = "kuberform-default-sg"
    Owner    = "infrastructure"
    Billing  = "costcenter"
    Role     = "kuberform-bastion"
    Provider = "https://github.com/kuberform"
  }
}

output "sg_default" {
  value = "${aws_default_security_group.default.id}"
}
