data "aws_caller_identity" "current" {}

resource "aws_lb" "kafka_nlb" {
  name = "nlb-kafka"

  subnets = "${var.subnets}"
  internal = "true"

  load_balancer_type = "network"
  enable_cross_zone_load_balancing = true
  enable_deletion_protection = true

  idle_timeout = 400
}

resource "aws_lb_target_group" "kafka_nlb_target_group" {
  count = "var.kafka_broker_count"
  name = "nlb-tg-kafka-${count.index}"
  port = "${count.index + var.kafka_port}"
  vpc_id = "${var.vpc_id}"
  deregistration_delay = 120
  protocol = "TCP"

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    protocol = "TCP"
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 10
    path = ""
    matcher = ""
  }
}

resource "aws_lb_target_group_attachment" "kafka_nlb_target_group_attachment" {
  count = "${var.kafka_broker_count}"
  target_group_arn = "${element(aws_lb_target_group.kafka_nlb_target_group.*.arn, count.index)}"
  target_id = "${element(var.kafka_instance_ids, count.index)}"
  port = "${count.index + var.kafka_port}"
}

resource "aws_lb_listener" "kafka_nlb_listener" {
  count = "${var.kafka_broker_count}"
  load_balancer_arn = "${aws_lb.kafka_nlb.arn}"
  port = "${count.index + var.kafka_port}"
  protocol = "TCP"

  default_action {
    target_group_arn = "${element(aws_lb_target_group.kafka_nlb_target_group.*.arn, count.index)}"
    type = "forward"
  }
}

resource "aws_vpc_endpoint_service" "vpce_provider" {
  acceptance_required = false
  network_load_balancer_arns = ["${aws_lb.kafka_nlb.arn}"]

  lifecycle {
    ignore_changes = [
      "allowed_principals"
    ]
  }
}

resource "aws_vpc_endpoint_service_allowed_principal" "current_account_whitelisted" {
  vpc_endpoint_service_id = "${aws_vpc_endpoint_service.vpce_provider.id}"
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
}

resource "aws_vpc_endpoint_service_allowed_principal" "kafka_vpce_allowed_principals" {
  count = "${length(var.vpce_whitelisted_accounts)}"
  vpc_endpoint_service_id = "${aws_vpc_endpoint_service.vpce_provider.id}"
  principal_arn = "arn:aws:iam::${element(var.vpce_whitelisted_accounts, count.index)}:root"
}
