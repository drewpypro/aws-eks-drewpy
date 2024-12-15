data "aws_autoscaling_group" "istio_ingress_asg" {
  name = aws_eks_node_group.istio_ingress.resources[0].autoscaling_groups[0].name
}

data "aws_instances" "istio_ingress_instances" {
  filter {
    name   = "tag:Name"
    values = ["istio-node"]
  }

  depends_on = [
    aws_eks_cluster.eks,
    aws_launch_template.worker_node_group
  ]

}

resource "aws_lb" "istio_ingress_nlb" {
  name               = "istio-ingress-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]
  enable_deletion_protection = false
  security_groups = [module.security_groups.security_group_ids["internet_nlb"]]
  tags = {
    Name = "istio-ingress-nlb"
  }

  depends_on = [
    aws_eks_cluster.eks,
    aws_launch_template.worker_node_group
  ]
}

resource "aws_lb_target_group" "istio_http_tg" {
  name        = "istio-http-tg"
  port        = 30080
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    port                = "30080"
    protocol            = "TCP"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "istio-http-tg"
  }
}

resource "aws_lb_target_group" "istio_https_tg" {
  name        = "istio-https-tg"
  port        = 30443
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    port                = "30443"
    protocol            = "TCP"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "istio-https-tg"
  }
}

resource "aws_lb_listener" "istio_http_listener" {
  load_balancer_arn = aws_lb.istio_ingress_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.istio_http_tg.arn
  }
}

resource "aws_lb_listener" "istio_https_listener" {
  load_balancer_arn = aws_lb.istio_ingress_nlb.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.istio_https_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "istio_http_attachment" {
  for_each         = toset(data.aws_instances.istio_ingress_instances.ids)
  target_group_arn = aws_lb_target_group.istio_http_tg.arn
  target_id        = each.key
  port             = 30080
}

resource "aws_lb_target_group_attachment" "istio_https_attachment" {
  for_each         = toset(data.aws_instances.istio_ingress_instances.ids)
  target_group_arn = aws_lb_target_group.istio_https_tg.arn
  target_id        = each.key
  port             = 30443
}