# Security Group for ALB
resource "aws_security_group" "alb" {
    name = "${var.env}-${var.service_name}-alb-sg"
    description = "ALB Security Group"
    vpc_id = var.vpc.id

    tags = {
        Name = "${var.env}-${var.service_name}-alb-http-sg"
    }
}

resource "aws_security_group_rule" "alb_http" {
    security_group_id = aws_security_group.alb.id
    type = "ingress"
    cidr_blocks = ["0.0.0.0/0"]
    to_port = "80"
    from_port = "80"
    protocol = "tcp"
    description = "Public HTTP Access Allowed"
}

resource "aws_security_group_rule" "alb_https" {
    security_group_id = aws_security_group.alb.id
    type = "ingress"
    cidr_blocks = ["0.0.0.0/0"]
    to_port = "443"
    from_port = "443"
    protocol = "tcp"
    description = "Public HTTPS Access Allowed"
}

resource "aws_security_group_rule" "alb" {
    security_group_id = aws_security_group.alb.id
    type = "egress"
    cidr_blocks = ["0.0.0.0/0"]
    to_port = "0"
    from_port = "0"
    protocol = "-1"
    description = "Public Access Allowed"
}

# ALB
resource "aws_lb" "this" {
    name = "${var.env}-${var.service_name}-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [
        aws_security_group.alb.id
    ]
    subnets = var.public_subnet_ids

    tags = {
        Name = "${var.env}-${var.service_name}-igw"
    }
}

# ALB Listener for HTTP
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.this.arn
    port = "80"
    protocol = "HTTP"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "ok"
            status_code = "200"
        }
    }
}

# ALB Listener for HTTPS
resource "aws_lb_listener" "https" {
    load_balancer_arn = aws_lb.this.arn
    certificate_arn   = var.acm.arn
    port              = "443"
    protocol          = "HTTPS"

    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.this.arn
    }
}

resource "aws_lb_listener_rule" "http_to_https" {
    listener_arn = aws_lb_listener.http.arn
    priority = 99
    
    action {
        type = "redirect"
        redirect {
            port = "443"
            protocol = "HTTPS"
            status_code = "HTTP_301"
        }
    }

    condition {
        host_header {
            values = [var.domain_name]
        }
    }
}

# Target Group
resource "aws_lb_target_group" "this" {
    name = "${var.env}-${var.service_name}-tg"
    vpc_id = var.vpc.id
    port = 80
    protocol = "HTTP"
    target_type = "instance"

    health_check {
        port = 80
        path = "/"
    }

    depends_on = [aws_lb.this]
}
