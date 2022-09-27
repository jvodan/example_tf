
resource "aws_vpc" "applications-vpc" {
  cidr_block = "10.111.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = false
  instance_tenancy = "default"
  tags = {
    Name = "applications-vpc"
    Environment = "var.app_environment"
    }
  }

resource "aws_subnet" "subnet-a" {
  cidr_block = "10.111.111.0/24"
  availability_zone = "ap-southeast-2a"
  tags = {
    Name = "subnet-a"
    Environment = "var.app_environment"
    }
  map_public_ip_on_launch = true
  vpc_id = aws_vpc.applications-vpc.id
  }

resource "aws_subnet" "subnet-b" {
  cidr_block = "10.111.222.0/24"
  availability_zone = "ap-southeast-2b"
  tags = {
    Name = "sunbet-b"
    Environment = "var.app_environment"
    }
  map_public_ip_on_launch = true
  vpc_id = aws_vpc.applications-vpc.id
  }

resource "aws_lb" "applications-load-balancer" {
  name = "applications-load-balancer"
  tags = {
    Name = "applications-load-balancer"
    Environment = "var.app_environment"
    }
  subnets         = [
    aws_subnet.subnet-a.id,
    aws_subnet.subnet-b.id
    ]
  security_groups = [
    aws_security_group.applications-security-group.id
    ]
  depends_on      = [
    aws_security_group.applications-security-group,
    aws_subnet.subnet-a,
    aws_subnet.subnet-b
    ]
  }

resource "aws_lb_target_group" "app-lb-target-group" {
  name = "app-lb-target-group"
  target_type = "ip"
  protocol = "HTTP"
  port = "443"
  tags = {
    Name = "applications-load-balancer-target-group"
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

resource "aws_security_group" "applications-security-group" {
  name = "applications-security-group"
  tags = {
    Name = "applications-security-group"
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

resource "aws_internet_gateway" "igw-a" {
  tags = {
    Name = "applications-internet-gateway"
    Environment = "var.app_environment"
    }
  vpc_id = aws_vpc.applications-vpc.id
  }




resource "aws_nat_gateway" "nat-gw-a" {
  tags = {
    Name = "nat-gw-a"
    Environment = "var.app_environment"
    }
  subnet_id = aws_subnet.subnet-a.id
  allocation_id = aws_eip.eip-a.id
  depends_on = [
    aws_internet_gateway.igw-a
    ]
  }

resource "aws_eip" "eip-a" {
  vpc = true
  }

resource "aws_nat_gateway" "nat-gw-b" {
  tags = {
    Name = "nat-gw-b"
    Environment = "var.app_environment"
    }
  subnet_id = aws_subnet.subnet-b.id
  allocation_id = aws_eip.eip-b.id
  depends_on = [
    aws_internet_gateway.igw-a
    ]
  }

resource "aws_eip" "eip-b" {
  vpc = true
  }

resource "aws_route_table" "route-table-a" {
  tags = {
    Name = "route-table-a"
    Environment = "var.app_environment"
    }
  vpc_id = aws_vpc.applications-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-a.id
    }
  }

resource "aws_route_table" "route-table-b" {
  tags = {
    Name = "route-table-b"
    Environment = "var.app_environment"
    }
  vpc_id = aws_vpc.applications-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id =  aws_internet_gateway.igw-a.id
    }
  }