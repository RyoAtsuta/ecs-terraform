# ECS Cluster
resource "aws_ecs_cluster" "this" {
    name = var.ecs_cluster_name

    tags = {
        Name = var.ecs_cluster_name
    }
}

# Task Definition
resource "aws_ecs_task_definition" "these" {
    for_each = var.task_definitions

    family = each.value.name
    container_definitions = each.value.task_definition

    tags = {
        Name = each.value.name
    }
}

# ECS Service
resource "aws_ecs_service" "these" {
    for_each = var.ecs_services

    name = each.value.name
    cluster = aws_ecs_cluster.this.name
    desired_count = each.value.desired_count
    task_definition = each.value.task_definition_name
    launch_type = "EC2"

    network_configuration {
        subnets = var.public_subnet_ids
        security_groups = [
            aws_security_group.ecs.id
        ]
    }

    load_balancer {
        target_group_arn = var.target_group_arn
        container_name = each.value.container_name
        container_port = each.value.container_port
    }

    tags = {
        Name = each.value.name
    }
}

# Security Group for ECS
resource "aws_security_group" "ecs" {
    name = "${var.env}-${var.service_name}-ecs-sg"
    description = "ECS Security Group"
    vpc_id = var.vpc_id

    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        from_port = 80
        to_port = 80
        protocol = "tcp"
        description = "All open for HTTP"
    }

    egress {
        cidr_blocks = ["0.0.0.0/0"]
        from_port = 0
        to_port = 0
        protocol = "-1"
        description = "All open for HTTP"
    }

    tags = {
        Name = "${var.env}-${var.service_name}-ecs-sg"
    }
}