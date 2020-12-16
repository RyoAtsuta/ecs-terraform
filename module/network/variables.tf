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

variable "vpc_cidr_block" {}

variable "public_subnet_cidr_blocks" {}