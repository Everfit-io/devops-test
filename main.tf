provider "aws" {
  region = var.aws_region
}

# S3
resource "aws_s3_bucket" "devops_test_app_bucket" {
  bucket = "my-app-bucket"
  acl    = "private"

  tags = {
    Name = "MyAppBucket"
  }
}

# RDS PostgreSQL
resource "aws_db_instance" "devops_test_app_db" {
  identifier         = "devops-test-app-db"
  engine             = "postgres"
  instance_class     = "db.t2.micro"
  allocated_storage   = 20
  username           = var.db_username
  password           = var.db_password
  db_name            = var.db_name
  publicly_accessible = false
  skip_final_snapshot = true

  tags = {
    Name = "DevOpsTestAppDB"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "devops_test_app_task" {
  family                   = "devops-test-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "app-container"
      image     = "${var.ecr_repository}:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      memoryReservation = 256
    }
  ])
}

# Load Balancer
resource "aws_elb" "devops_test_app_load_balancer" {
  name               = "devops-test-app-load-balancer"
  availability_zones = ["us-west-2a", "us-west-2b"]  

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold  = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "devops-test-app-load-balancer"
  }
}

# Route 53
resource "aws_route53_record" "devops_test_app_record" {
  zone_id = "Z3M3LMX11YY45D" 
  name    = "sample-app.example.com"
  type    = "A"

  alias {
    name                   = aws_elb.devops_test_app_load_balancer.dns_name
    zone_id                = aws_elb.devops_test_app_load_balancer.zone_id
    evaluate_target_health = true
  }
}

# Target group 
resource "aws_lb_target_group" "devops_test_app_target_group" {
  name     = "devops-test-app-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpcdepopstest" 
}

# Point target group to ELB
resource "aws_lb_listener" "devops_test_app_listener" {
  load_balancer_arn = aws_elb.devops_test_app_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    
    target_group_arn = aws_lb_target_group.devops_test_app_target_group.arn
  }
}

# ECS Service
resource "aws_ecs_service" "devops_test_app_service" {
  name            = var.ecs_service_name
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.devops_test_app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = ["subnet-0123456789abcdef0"]
    security_groups = [aws_security_group.devops_test_app_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.devops_test_app_target_group.arn
    container_name   = "devops-test-container"
    container_port   = 80
  }
}

# ECR Repository
resource "aws_ecr_repository" "devops_test_app_ecr" {
  name = var.ecr_repository

  tags = {
    Name = "DevOpsTestAppECR"
  }
}

# EC2 Instance
resource "aws_instance" "devops_test_app_instance" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "devops-test-app-instance"
  }
}

# Attach ELB with EC2
resource "aws_elb_attachment" "devops_test_app_attachment" {
  elb      = aws_elb.devops_test_app_load_balancer.id
  instance = aws_instance.devops_test_app_instance.id
}

# Auto Scaling Group
resource "aws_launch_configuration" "devops_test_app_lc" {
  name          = "devops-test-app-launch-configuration"
  image_id     = "ami-0c55b159cbfafe1f0" 
  instance_type = "t2.micro"

  lifecycle {
    create_before_destroy = true
  }

  iam_instance_profile = aws_iam_instance_profile.devops_test_app_ecs_instance_profile.id

  security_groups = [aws_security_group.devops_test_app_sg.id]
}

resource "aws_autoscaling_group" "devops_test_app_asg" {
  launch_configuration = aws_launch_configuration.devops_test_app_lc.id
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2
  vpc_zone_identifier = ["subnet-0123456789abcdef0"] 

  tag {
    key                 = "Name"
    value               = "devops-test-app-instance"
    propagate_at_launch = true
  }
}

# IAM Role for ECS
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
}

# Security Group for EC2 and Load Balancer
resource "aws_security_group" "devops_test_app_sg" {
  name        = "devops-test-app-security-group"
  description = "Allow HTTP traffic"
  vpc_id     = "vpcdepopstest"  

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"]
  }
}
