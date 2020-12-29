variable "region" {
    description = "region"
    type = string
    default = "ap-northeast-1"
}

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

variable "domain_name" {
    description = ""
    type = string
    default = "ryoryou.ml"
}

variable "ssh_cidr_blocks" {
    description = ""
    type = list
}