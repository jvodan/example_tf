resource "aws_iam_role" "ecs_task_execution_role" {
  name = "apps-ecsTaskRole"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  #role       = aws_iam_role.ecs_task_execution_role.name
  role = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_ecs_task_definition" "applications-opta" {
  network_mode = "awsvpc"
  memory = 2048
  cpu = 1024
  family = "opta"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  tags = {
    Name = "applications-opta"
    Environment = "var.app_environment.test"
    }
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
      {
        name = "applications-opta"
	image = "library/httpd:2.4"
	#image = "910122582945.dkr.ecr.ap-southeast-2.amazonaws.com/applications-container-registry:applications_opta"
        essential = true
        cpu = 10
        memory = 256
        networkMode = "awsvpc"
        portMappings = [
          {
            containerPort = 80
            hostPort = 80
            }
          ]
        }
      ])
  }

resource "aws_lb" "applications-opta" {
  name = "applications-opta"
  tags = {
    Name = "applications-opta"
    Environment = "var.app_environment"
    }
  subnets         = [
    aws_subnet.subnet-opta-a.id, aws_subnet.subnet-opta-b.id
    ]
  security_groups = [
    aws_security_group.opta-security-group.id
    ]
  depends_on      = [
    aws_security_group.opta-security-group,
    aws_subnet.subnet-opta-a, aws_subnet.subnet-opta-b
    ]
  }

resource "aws_lb_target_group" "applications-opta" {
  name = "applications-opta"
  target_type = "ip"
  protocol = "HTTP"
  port = 80
  tags = {
    Name = "applications-opta"
    Environment = "var.app_environment"
    }
  vpc_id = aws_vpc.applications-vpc.id
  health_check {
    healthy_threshold   = 3
    interval            = 300
    protocol            = "HTTP"
    matcher             = 200
    timeout             = 3
    path                = "/"
    unhealthy_threshold = 2
    }
  }

resource "aws_lb_listener" "applications-opta" {
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  tags = {
    Name = "applications-opta"
    Environment = "var.app_environment"
    }
  load_balancer_arn = aws_lb.applications-opta.arn
  certificate_arn = "arn:aws:acm:ap-southeast-2:910122582945:certificate/487f72fc-0e54-4e57-82b2-fe152294cf29"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.applications-opta.arn
    }
  }


#note subnet a 10 and subnet b +1 =11 not a standard but adds clarity up to user but ...

resource "aws_subnet" "subnet-opta-a" {
  cidr_block = "10.111.10.0/24"
  availability_zone = "ap-southeast-2a"
  tags = {
    Name = "subnet-opta-a"
    Environment = "var.app_environment"
    }
  vpc_id = aws_vpc.applications-vpc.id
  }

resource "aws_subnet" "subnet-opta-b" {
  cidr_block = "10.111.11.0/24"
  availability_zone = "ap-southeast-2b"
  tags = {
    Name = "subnet-opta-b"
    Environment = "var.app_environment"
    }
  vpc_id = aws_vpc.applications-vpc.id
  }



resource "aws_route_table_association" "applications-opta-a" {
  subnet_id = aws_subnet.subnet-opta-a.id
  route_table_id = aws_route_table.route-table-vpc.id
  }

resource "aws_route_table_association" "applications-opta-b" {
  subnet_id = aws_subnet.subnet-opta-b.id
  route_table_id = aws_route_table.route-table-vpc.id
  }





resource "aws_security_group" "opta-security-group" {
  name = "opta-security-group"
  tags = {
    Name = "opta-security-group"
    Environment = "var.app_environment"
    }
  vpc_id = aws_vpc.applications-vpc.id
  ingress {
    from_port        = 0
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    }
  }

resource "aws_route53_record" "opta-cname" {
  zone_id = "ZARIYTT7C12LN"
  name    = "opta"
  type    = "CNAME"
	
  alias {
    name                   = aws_lb.applications-opta.dns_name
    zone_id                = aws_lb.applications-opta.zone_id
    evaluate_target_health = true
  }

}
