resource "aws_ecs_cluster" "devops_test" {
  name = "devops_test"
}

resource "aws_ecs_cluster_capacity_providers" "devops_test" {
  cluster_name       = aws_ecs_cluster.devops_test.name
  capacity_providers = ["FARGATE_SPOT"]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
  }
}

resource "aws_iam_role" "task_execution" {
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
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "trust_task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "devops_test_webapp" {
  name = "/ecs/devops_test_webapp"
}

resource "aws_ecs_task_definition" "devops_test_web" {
  family                   = "devops_test_webapp"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_execution.arn
  cpu                      = 256
  memory                   = 512
  container_definitions = jsonencode([
    {
      name      = "webapp"
      image     = var.webapp_image
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/devops_test_webapp"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
      portMappings = [
        {
          containerPort = var.webapp_port
          hostPort      = var.webapp_port
          protocol      = "tcp"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "devops_test_web" {
  name            = "devops_test_webapp"
  cluster         = aws_ecs_cluster.devops_test.id
  task_definition = aws_ecs_task_definition.devops_test_web.arn
  desired_count   = 1
  network_configuration {
    subnets          = [for sn in aws_subnet.devops_test : sn.id]
    security_groups  = [aws_security_group.devops_test_web.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.devops_test_web.arn
    container_name   = "webapp"
    container_port   = var.webapp_port
  }
  launch_type = "FARGATE"
}
