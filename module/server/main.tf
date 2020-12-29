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
    network_mode = "bridge"

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

    load_balancer {
        target_group_arn = var.target_group_arn
        container_name = each.value.container_name
        container_port = each.value.container_port
    }

    depends_on = [aws_ecs_task_definition.these]

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

    ingress {
        cidr_blocks = var.ssh_cidr_blocks
        from_port = 22
        to_port = 22
        protocol = "tcp"
        description = "My Public IP Address for SSH"
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

# AMI
data "aws_ami" "ecs_optimized" {
    owners = ["amazon"]

    filter {
        name = "name"
        values = ["amzn-ami-2018.03.20200108-amazon-ecs-optimized"]
    }
}

# Launch Template
resource "aws_launch_template" "ecs" {
    name = var.launch_template.name
    description = var.launch_template.name
    image_id = data.aws_ami.ecs_optimized.id
    update_default_version = true
    instance_type = var.launch_template.instance_type
    key_name = var.key_pair.name
    user_data = var.launch_template.user_data

    network_interfaces {
        associate_public_ip_address = true
        security_groups = [aws_security_group.ecs.id]
    }

    iam_instance_profile {
        arn = aws_iam_instance_profile.ecs_instance.arn
    }

    depends_on = [aws_security_group.ecs]

    tags = {
        Name = var.launch_template.name
    }
}

# Key Pair
resource "aws_key_pair" "operator" {
    key_name = var.key_pair.name
    public_key = var.key_pair.public_key

    tags = {
        Name = var.key_pair.name
    }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "this" {
    name = var.autoscaling_group.name
    max_size = var.autoscaling_group.max_size
    min_size = var.autoscaling_group.min_size
    default_cooldown = var.autoscaling_group.default_cooldown

    launch_template {
        id = aws_launch_template.ecs.id
        version = "$Latest"
    }

    health_check_grace_period = var.autoscaling_group.health_check_grace_period
    health_check_type = "ELB"
    desired_capacity = var.autoscaling_group.desired_capacity
    force_delete = false
    vpc_zone_identifier = var.public_subnet_ids
    target_group_arns = [var.target_group_arn]
    termination_policies = [var.autoscaling_group.termination_policy]
    # suspended_processes = [var.autoscaling_group.suspended_process]

    tag {
        key = "Name"
        value = var.autoscaling_group.instance_tag
        propagate_at_launch = true
    }
}

# IAM
resource "aws_iam_role" "ecs_instance" {
    name = "ecsInstanceRole"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

    tags = {
        Name = "${var.env}-${var.service_name}-ecs-instance-role"
    }
}

data "aws_iam_policy" "ecs_instance" {
    arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_policy_attachment" "ecs_instance" {
    name = "ecsInstancePolicyAttachment"
    roles = [aws_iam_role.ecs_instance.name]
    policy_arn = data.aws_iam_policy.ecs_instance.arn
}

resource "aws_iam_instance_profile" "ecs_instance" {
    name = "ecsInstanceProfile"
    role = aws_iam_role.ecs_instance.name
}
