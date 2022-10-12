
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







resource "aws_internet_gateway" "igw-a" {
  tags = {
    Name = "applications-internet-gateway"
    Environment = "var.app_environment"
    }
  vpc_id = aws_vpc.applications-vpc.id
  }


resource "aws_route_table" "route-table-vpc" {
  tags = {
    Name = "route-table-opt"
    Environment = "var.app_environment"
    }
  vpc_id = aws_vpc.applications-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-a.id
    }
  }





