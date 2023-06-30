terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Replace with your desired AWS region
}

# Filter private subnets by Tag
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  tags = {
    Name = var.subnet_private_tag
  } 
}

# Filter public subnets by Tag
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  tags = {
    Name = var.subnet_public_tag
  } 
}

# Read each value of the private subnets
data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

# Read each value of the public subnets
data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

#Store the ID of the subnets in variables
locals {
  public_subnet_ids  = [for a in data.aws_subnet.public : a.id]
  private_subnet_ids = [for b in data.aws_subnet.private : b.id]
}

#Configuring security groups for load balancer
resource "aws_security_group" "lb-ecs" {
  name        = "ecs-alb-security-group"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "default" {
  name            = "ecs-alb"
  subnets         = local.public_subnet_ids
  security_groups = [aws_security_group.lb-ecs.id]
}

resource "aws_lb_target_group" "hello_world" {
  name        = "ecs-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "hello_world" {
  load_balancer_arn = aws_lb.default.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.hello_world.id
    type             = "forward"
  }
}

# Creation of cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"
}

# Configuring capacity providers for cluster
resource "aws_ecs_cluster_capacity_providers" "ecs_cluster" {
  cluster_name       = aws_ecs_cluster.ecs_cluster.name
  capacity_providers = ["FARGATE"]
}

# Creation of task definition for the cluster
resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "hello-world-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048

  container_definitions = <<DEFINITION
[
  {
    "image": "registry.gitlab.com/architect-io/artifacts/nodejs-hello-world:latest",
    "cpu": 1024,
    "memory": 2048,
    "name": "hello-world-app",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000
      }
    ]
  }
]
DEFINITION
}

# Security group for the cluster communication
resource "aws_security_group" "ecs_task" {
  name        = "ecs-task-security-group"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 3000
    to_port         = 3000
    security_groups = [aws_security_group.lb-ecs.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Creation of the service of the cluster and relate with the ALB
resource "aws_ecs_service" "ecs_service" {
  name            = "ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.ecs_task.id]    
    subnets         = local.private_subnet_ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.hello_world.id
    container_name   = "hello-world-app"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.hello_world]


}





