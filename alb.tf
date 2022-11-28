resource "aws_lb" "this" {
  name               = "chainlink-${var.environment}-node"
  internal           = false
  load_balancer_type = "network"

  dynamic "subnet_mapping" {
    for_each = { for subnet_map in var.subnet_mapping : subnet_map.subnet_id => subnet_map }
    content {
      subnet_id     = subnet_mapping.value.subnet_id
      allocation_id = subnet_mapping.value.allocation_id
    }
  }

  tags = {
    Name = "${var.project}-${var.environment}-node"
  }
}

resource "random_string" "alb_prefix_ui" {
  keepers = {
    # Generate a new id each time we change chainlink_ui_port
    port = var.tls_ui_enabled && var.tls_type == "import" ? var.tls_chainlink_ui_port : var.chainlink_ui_port
  }

  length  = 4
  upper   = false
  special = false
}

resource "random_string" "alb_prefix_node" {
  keepers = {
    # Generate a new id each time we change chainlink_node_port
    port = var.chainlink_node_port
  }

  length  = 4
  upper   = false
  special = false
}

resource "aws_lb_target_group" "ui" {
  name                 = "chainlink-${var.environment}-ui-${random_string.alb_prefix_ui.result}"
  port                 = var.tls_ui_enabled && var.tls_type == "import" ? var.tls_chainlink_ui_port : var.chainlink_ui_port
  protocol             = "TCP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 10
  preserve_client_ip   = true

  health_check {
    enabled             = true
    path                = "/health"
    port                = var.chainlink_ui_port
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    protocol            = "HTTP"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "node" {
  name                 = "chainlink-${var.environment}-node-${random_string.alb_prefix_node.result}"
  port                 = var.chainlink_node_port
  protocol             = "TCP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = 10
  preserve_client_ip   = true

  health_check {
    enabled             = true
    path                = "/health"
    port                = var.chainlink_ui_port
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    protocol            = "HTTP"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "ui" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.tls_ui_enabled && var.tls_type == "import" ? var.tls_chainlink_ui_port : var.chainlink_ui_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ui.arn
  }
}

resource "aws_lb_listener" "node" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.chainlink_node_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.node.arn
  }
}
