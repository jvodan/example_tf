
resource "aws_ecs_service" "applications-abs" {
  name = "applications-abs"
  launch_type = "FARGATE"
  desired_count = 1
  tags = {
    Name = "applications-abs"
    Environment = "var.app_environment"
    }
  depends_on = [
    aws_lb.abs,
    aws_lb_listener.abs
    ]
  cluster = aws_ecs_cluster.applctns-cntnr-srvc-clstr.id
  task_definition = aws_ecs_task_definition.applications-abs.arn
  load_balancer {
    target_group_arn = aws_lb_target_group.abs.arn
    container_name   = "applications-abs"
    container_port   = "84"
    }
  network_configuration {
    subnets = [aws_subnet.abs-public-a.id]
    assign_public_ip = true
    security_groups = [aws_security_group.abs-security-group.id]
    }
  }
