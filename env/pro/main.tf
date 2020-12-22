provider "aws" {
    version = "= 3.0.0"
    profile = "default"
    region = var.region
}

terraform {
    required_version = "= 0.13.5"

    backend "s3" {
        bucket = "ryoryou-terraform-state-bucket"
        key = "bmake-terraform/terraform.tfstate"
        region = "ap-northeast-1"
    }
}

module "network" {
    source = "../../module/network"
    vpc_cidr_block = "10.0.0.0/16"
    public_subnet_cidr_blocks = {
        ap-northeast-1a = "10.0.1.0/24"
        ap-northeast-1c = "10.0.2.0/24"
    }
}

module "route53" {
    source = "../../module/route53"
    domain_name = var.domain_name
    alb = {
        dns_name = module.alb.this_lb_dns_name
        zone_id = module.alb.this_lb_zone_id
    }
}

# https://registry.terraform.io/modules/terraform-aws-modules/acm/aws/latest
module "acm" {
    source = "terraform-aws-modules/acm/aws"
    version = "~> v2.0"

    domain_name = var.domain_name
    zone_id = module.route53.this_route53_zone_zone_id

    subject_alternative_names = [
        "${var.domain_name}",
        "dev.${var.domain_name}",
        "stg.${var.domain_name}",
        "www.${var.domain_name}"
    ]

    tags = {
        Name = "${var.env}-${var.service_name}-${var.domain_name}-acm"
    }
}

module "alb" {
    source = "../../module/alb"

    vpc = {
        id = module.network.this_vpc_id
    }
    public_subnet_ids = module.network.public_subnet_ids
    acm = {
        arn = module.acm.this_acm_certificate_arn
    }
    domain_name = var.domain_name
}

# module "ecr" {
#     source = "../../module/ecr"
# }

# WIP: container.json, migration.jsonの環境変数を埋めるように環境変数をtfvars.terraformでセットする
module "server" {
    source = "../../module/server"

    vpc_id = module.network.this_vpc_id
    target_group_arn = module.alb.this_target_group_arn
    public_subnet_ids = module.network.public_subnet_ids

    ecs_cluster_name = "${var.env}-${var.service_name}-container-cluster"
    ecs_services = {
        container = {
            name = "${var.env}-${var.service_name}-container-service"
            desired_count = 1
            container_name = "nginx"
            container_port = 80
            task_definition_name = "${var.env}-${var.service_name}-nginx-task"
        }
    }
    task_definitions = {
        # container = {
        #     name = "${var.env}-${var.service_name}-container-task"
        #     task_definition = file("${path.module}/task_definition/container.json") # ---------- WIP
        # }
        nginx = {
            name = "${var.env}-${var.service_name}-nginx-task"
            task_definition = file("${path.module}/task_definition/nginx.json")
        }  
    }
    
    # run_tasks = {
    #     migration = file("${path.module}/task_definition/migration.json")
    # }

    launch_template = {
        name = "${var.env}-${var.service_name}-container-lt"
        user_data = base64encode(file("${path.module}/user_data/server.sh"))
        instance_type = "t3a.small"
    }

    key_pair = {
        name = "bmake"
        public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDORRIysbjvH52ZGzSD/EU9WnakUE43/P3u3wCeYsteMV3MbxXsDd2tVDDL4Gvp9VQmzEgg5dr/8bThC5ydvRzHRLg0XxQj4aGeEazwINdiGqflkDBD7vYc4vqNGsPGPIpr2O2YcvlCM8E3Ixaci8naxUDRLC6ydm+lmJ+0ag+aJ6/agDoeCRpebv4MNCSqN/FIq4YKIUU4KxoHDPK+qlv2siy6jDcL7eHWW3/3bgWig2Cnnkb8SyNmEYdSGAzNO1WwlCgfW23gJU4kDCwo9x+sKZnZ9zM2ZGK2RZbJZvGOcVHcPxYf4wHTTNyAq+7fiaKmEZNOIXpYcAiV9SXZvySl atsutaryou@atsutaryous-MacBook-puro.local"
    }

    autoscaling_group = {
        name = "${var.env}-${var.service_name}-container-asg"
        max_size = "1"
        min_size = "1"
        default_cooldown = "300"
        health_check_grace_period = "300"
        desired_capacity = "1"
        termination_policy = "Default"
        suspended_process = "HealthCheck"
        instance_tag = "${var.env}-${var.service_name}-container-instance"
    }

    depends_on = [module.alb]
}
