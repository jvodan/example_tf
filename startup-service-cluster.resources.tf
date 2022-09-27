
resource "aws_ecs_cluster" "applications-container-service-cluster" {
  name = "applications-container-service-cluster"
  }

resource "aws_kms_key" "applications-cluster-key" {
  description = "applications-cluster-key"
  deletion_window_in_days = 10
  is_enabled = true
  enable_key_rotation = false
  multi_region = false
  tags = {
    Name = "applications-cluster-key"
    Environment = "var.app_environment"
    }
  }

resource "aws_cloudwatch_log_group" "applications-log-group" {
  tags = {
    Name = "applications-log-group"
    Environment = "var.app_environment"
    }
  }

resource "aws_iam_role" "applications-iam-role" {
  name = "applications-iam-role"
  tags = {
    Name = "applications-iam-role"
    Environment = "var.app_environment"
    }
  assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Sid    = ""
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
            }
          }
        ]
      })
  }

resource "aws_iam_role_policy_attachment" "applications-iam-role-policy-attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
  role = aws_iam_role.applications-iam-role.id
  }

resource "aws_acm_certificate" "applications-acm-certificate" {
  tags = {
    Name = "applications-acm-certificate"
    Environment = "var.app_environment"
    }
  domain_name       = "dougs.engines.org"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
    }
  }
