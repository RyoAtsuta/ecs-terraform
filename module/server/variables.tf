variable "service_name" {
    description = "Service Name"
    type = string
    default = "bmake"
}

variable "env" {
    description = "Environment Name (dev | stg | pro)"
    type = string
    default = "pro"
}

variable "vpc_id" {
    description = ""
    type = string
}

variable "target_group_arn" {
    description = ""
    type = string
}

variable "ecs_cluster_name" {
    description = ""
    type = string
}

variable "ecs_services" {
    description = ""
    type = map
}

variable "task_definitions" {
    description = ""
    type = map
}

variable "public_subnet_ids" {
    description = ""
    type = list
}

variable "launch_template" {
    description = ""
    type = map
}

variable "key_pair" {
    description = ""
    type = map
}

variable "autoscaling_group" {
    description = ""
    type = map
}
