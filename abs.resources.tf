
resource "aws_ecs_task_definition" "applications-abs" {
  network_mode = "awsvpc"
  memory = 2048
  cpu = 1024
  family = "abs"
  tags = {
    Name = "applications-abs"
    Environment = "var.app_environment"
    }
  execution_role_arn = aws_iam_role.applications-execution-role.arn
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
      {
        name = "applications-abs"
        image = "library/httpd:2.4"
        #image = "910122582945.dkr.ecr.ap-southeast-2.amazonaws.com/applications-container-registry:applications_abs"
        essential = true
        cpu = 10
        memory = 512
        networkMode = "awsvpc"
        portMappings = [
          {
            containerPort = 84
            hostPort = 84
            }
          ]
        }
      ])
  }

resource "aws_subnet" "abs-public-a" {
  cidr_block = "10.111.101.0/24"
  availability_zone = "ap-southeast-2a"
  tags = {
    Name = "abs-public-a"
    Environment = "var.app_environment"
    }
   map_public_ip_on_launch = true
  vpc_id = aws_vpc.applications-vpc.id
  }

resource "aws_subnet" "abs-public-b" {
  cidr_block = "10.111.202.0/24"
  availability_zone = "ap-southeast-2b"
  tags = {
    Name = "abs-public-b"
    Environment = "var.app_environment"
    }
   map_public_ip_on_launch = false
  vpc_id = aws_vpc.applications-vpc.id
  }

resource "aws_security_group" "abs-security-group" {
  name = "abs-security-group"
  tags = {
    Name = "abs-security-group"
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

#resource "aws_internet_gateway" "abs-internet-gateway" {
  #tags = {
    #Name = "abs-internet-gateway"
    #Environment = "var.app_environment"
    #}
  #vpc_id = aws_vpc.applications-vpc.id
  #}



resource "aws_lb" "abs" {
  name = "abs"
  tags = {
    Name = "abs"
    Environment = "var.app_environment"
    }
  subnets         = [
    aws_subnet.abs-public-a.id,
    aws_subnet.abs-public-b.id
    ]
  security_groups = [
    aws_security_group.abs-security-group.id
    ]
  depends_on      = [
    aws_security_group.abs-security-group,
    aws_subnet.abs-public-a,
    aws_subnet.abs-public-b
    ]
  }

resource "aws_lb_target_group" "abs" {
  name = "abs"
  target_type = "ip"
  protocol = "HTTP"
  port = 84
  tags = {
    Name = "abs"
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

resource "aws_lb_listener" "abs" {
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  tags = {
    Name = "abs"
    Environment = "var.app_environment"
    }
  load_balancer_arn = aws_lb.abs.arn
  certificate_arn = "arn:aws:acm:ap-southeast-2:910122582945:certificate/487f72fc-0e54-4e57-82b2-fe152294cf29"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.abs.arn
    }
  }

resource "aws_route_table" "abs-route-table" {
  tags = {
    Name = "abs-route-table"
    Environment = "var.app_environment"
    }
  vpc_id = aws_vpc.applications-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.applications-internet-gateway.id
    }
}

resource "aws_route_table_association" "abs-public-a" {
  subnet_id = aws_subnet.abs-public-a.id
  route_table_id = aws_route_table.abs-route-table.id
  }

resource "aws_route_table_association" "abs-public-b" {
  subnet_id = aws_subnet.abs-public-b.id
  route_table_id = aws_route_table.abs-route-table.id
  }

resource "aws_route53_record" "abs" {
  name = "abs"
  zone_id = "ZARIYTT7C12LN"
  type = "CNAME"
  alias {
    name                   = aws_lb.abs.dns_name
    zone_id                = aws_lb.abs.zone_id
    evaluate_target_health = true
    }
  }
