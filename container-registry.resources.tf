
resource "aws_ecr_repository" "applications-container-registry" {
  name = "applications-container-registry"
  image_tag_mutability = "IMMUTABLE"
  tags = {
    Name = "applications-container-registry"
    Environment = "var.app_environment"
    }
  }

resource "aws_ecr_repository_policy" "applications-container-registry" {
  repository = aws_ecr_repository.applications-container-registry.name
  policy     = <<LINES
  {
    "Version": "2008-10-17",
    "Statement": [
      {
        "Sid": "adds full ecr access to the demo repository",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetLifecyclePolicy",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
          ]
        }
      ]
    }
  LINES
  }

resource "null_resource" "applications-container-registry-images-1663722996" {
  provisioner "local-exec" {
    command = <<LINES
    `aws ecr get-login-password | docker login --username AWS --password-stdin 910122582945.dkr.ecr.ap-southeast-2.amazonaws.com` &&
    docker push 910122582945.dkr.ecr.ap-southeast-2.amazonaws.com/applications-container-registry:applications_abs;
    docker push 910122582945.dkr.ecr.ap-southeast-2.amazonaws.com/applications-container-registry:applications_billing_engine;
    docker push 910122582945.dkr.ecr.ap-southeast-2.amazonaws.com/applications-container-registry:applications_longitude;
    docker push 910122582945.dkr.ecr.ap-southeast-2.amazonaws.com/applications-container-registry:applications_sura;
    docker push 910122582945.dkr.ecr.ap-southeast-2.amazonaws.com/applications-container-registry:applications_opta; echo 0
    LINES
    }
  depends_on = [
    aws_ecr_repository_policy.applications-container-registry
    ]
  }