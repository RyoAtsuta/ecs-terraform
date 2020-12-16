output "this_lb_dns_name" {
    description = ""
    value = aws_lb.this.dns_name
}

output "this_lb_zone_id" {
    description = ""
    value = aws_lb.this.zone_id
}

output "this_target_group_id" {
    description = ""
    value = aws_lb_target_group.this.id
}

output "this_target_group_arn" {
    description = ""
    value = aws_lb_target_group.this.arn
}