resource "aws_alb" "devops_test_web" {
  name               = "devops-test-web"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.devops_test_web.id]

  subnets = [for sn in aws_subnet.devops_test : sn.id]
}

resource "aws_lb_target_group" "devops_test_web" {
  name        = "devops-test-web"
  port        = var.webapp_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.devops_test.id
  target_type = "ip"

  health_check {
    enabled = true
    path    = var.webapp_healthcheck_path
  }
}

resource "aws_alb_listener" "devops_test_web" {
  load_balancer_arn = aws_alb.devops_test_web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_alb_listener" "devops_test_tls" {
  load_balancer_arn = aws_alb.devops_test_web.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.devops_test_web_cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.devops_test_web.arn
  }
  lifecycle {
    replace_triggered_by = [aws_lb_target_group.devops_test_web]
  }
}
