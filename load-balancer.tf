/*
resource "aws_lb" "controller" {
  name               = "kuberform-alb-controller"
  internal           = false
  subnets            = ["${aws_subnet.bastion.*.id}"]
  enable_http2       = true
  load_balancer_type = "application"
  ip_address_type    = "dualstack"

  security_groups = [
    "${aws_security_group.alb.id}",
    "${aws_security_group.controller.id}",
  ]

  tags {
    Name    = "kuberform-alb-controller-${data.aws_region.current.name}"
    Owner   = "infrastructure"
    Billing = "costcenter"
    Role    = "kuberform-controller"
  }
}

resource "aws_route53_record" "apex" {
  zone_id = "${aws_route53_zone.dynamic_dns.zone_id}"
  name    = "${data.aws_region.current.name}.k8s.audios.cloud"
  type    = "A"

  alias {
    name                   = "${aws_lb.controller.dns_name}"
    zone_id                = "${aws_lb.controller.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "api" {
  zone_id = "${aws_route53_zone.dynamic_dns.zone_id}"
  name    = "api.${data.aws_region.current.name}.k8s.audios.cloud"
  type    = "A"

  alias {
    name                   = "${aws_lb.controller.dns_name}"
    zone_id                = "${aws_lb.controller.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_lb_target_group" "controllers" {
  name     = "kuberform-controller-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"

  health_check {
    interval = 10
    path     = "/healthz"
    port     = "traffic-port"
    protocol = "HTTP"
    matcher  = "200-499"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "controller_http" {
  load_balancer_arn = "${aws_lb.controller.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${module.certificate.certificate_arn}"

  default_action {
    target_group_arn = "${aws_lb_target_group.controllers.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "controller_https" {
  load_balancer_arn = "${aws_lb.controller.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.controllers.arn}"
    type             = "forward"
  }
}

resource "aws_security_group" "alb" {
  name        = "kuberform-alb-sg"
  description = "Application Load Balancer for Kubernetes."
  vpc_id      = "${aws_vpc.main.id}"

  revoke_rules_on_delete = true

  tags {
    Name    = "kuberform-alb-sg"
    Owner   = "infrastructure"
    Billing = "costcenter"
    Role    = "kuberform-controller"
  }
}

resource "aws_security_group_rule" "alb-tcp-ingress" {
  type             = "ingress"
  from_port        = 0
  to_port          = 65535
  protocol         = "tcp"
  description      = "TCP Ingress"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = "${aws_security_group.alb.id}"
}

resource "aws_security_group_rule" "alb-tcp-egress" {
  type             = "egress"
  from_port        = 0
  to_port          = 65535
  protocol         = "tcp"
  description      = "TCP Egress"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = "${aws_security_group.alb.id}"
}

resource "aws_security_group_rule" "alb-icmp-egress" {
  type             = "egress"
  from_port        = -1
  to_port          = -1
  protocol         = 1
  description      = "ICMP Egress"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = "${aws_security_group.alb.id}"
}

resource "aws_security_group_rule" "alb-icmp-ingress" {
  type             = "ingress"
  from_port        = -1
  to_port          = -1
  protocol         = 1
  description      = "ICMP Ingress"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = "${aws_security_group.alb.id}"
}

output "sg_alb" {
  value = "${aws_security_group.alb.id}"
}

output "tg_controller" {
  value = "${aws_lb_target_group.controllers.arn}"
}
*/

