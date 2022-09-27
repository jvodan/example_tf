
resource "aws_ecs_service" "applications-opta" {
  name = "applications-opta"
  launch_type = "FARGATE"
  desired_count = 1
  tags = {
    Name = "applications-opta"
    Environment = "var.app_environment"
    }
  depends_on = [
    aws_lb.applications-opta,
    aws_lb_listener.applications-opta
    ]
  cluster = aws_ecs_cluster.applications-container-service-cluster.id
  task_definition = aws_ecs_task_definition.applications-opta.arn
  load_balancer {
    target_group_arn = aws_lb_target_group.applications-opta.arn
    container_name   = "applications-opta"
    container_port   = "80"
    }
  network_configuration {
    subnets = [aws_subnet.subnet-a.id]
    security_groups =[aws_security_group.applications-security-group.id]
    }
  }
