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

variable "user_data" {
    description = ""
    type = string
}

variable "task_definitions" {
    description = ""
    type = map
}

variable "public_subnet_ids" {
    description = ""
    type = list
}