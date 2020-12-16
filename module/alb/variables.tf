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

variable "vpc" {}

variable "public_subnet_ids" {}

variable "acm" {}

variable "domain_name" {}