output "this_vpc_id" {
    description = ""
    value = aws_vpc.this.id
}

output "public_subnet_ids" {
    value = [for public_subnet in aws_subnet.publics : public_subnet.id]
}