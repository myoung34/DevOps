resource "aws_ecr_repository" "cloud-custodian" {
  name = "cloud-custodian"
}

resource "aws_cloudwatch_log_group" "cloud-custodian" {
  name = "cloud-custodian"
}

resource "aws_ecs_cluster" "cloud-custodian" {
  name = "cloud-custodian"
}

resource "aws_ecs_service" "cloud-custodian" {
  name                               = "cloud-custodian"
  cluster                            = "${aws_ecs_cluster.cloud-custodian.arn}"
  task_definition                    = "${aws_ecs_task_definition.cloud-custodian.arn}"
  desired_count                      = "1"
  deployment_maximum_percent         = "100"
  deployment_minimum_healthy_percent = "0"
  launch_type                        = "FARGATE"

  network_configuration {
    security_groups = ["${var.security_group_id}"]
    subnets         = ["${var.subnet_id}"]
  }
}

resource "aws_ecs_task_definition" "cloud-custodian" {
  family                   = "cloud-custodian"
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  container_definitions    = <<DEFINITION
[
    {
        "name": "cloud-custodian",
        "image": "${aws_ecr_repository.cloud-custodian.repository_url}:latest",
        "essential": true,
        "entryPoint": [],
        "mountPoints": [],
        "volumesFrom": [],
         "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "cloud-custodian",
                "awslogs-region": "${var.region}",
                "awslogs-stream-prefix": "/"
            }
        }
    }
]
DEFINITION
  task_role_arn            = "${aws_iam_role.cloud-custodian.id}"
  execution_role_arn       = "${aws_iam_role.cloud-custodian.id}"
  requires_compatibilities = [
    "FARGATE"
  ]
}

