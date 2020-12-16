# VPC
resource "aws_vpc" "this" {
    cidr_block = var.vpc_cidr_block

    tags = {
        Name = "${var.env}-${var.service_name}-vpc"
    }
}

resource "aws_subnet" "publics" {
    for_each = var.public_subnet_cidr_blocks

    cidr_block = each.value
    vpc_id = aws_vpc.this.id
    availability_zone = each.key

    tags = {
        Name = "${var.env}-${var.service_name}-public-subnet-${each.key}"
    }
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
    vpc_id = aws_vpc.this.id

    tags = {
        Name = "${var.env}-${var.service_name}-igw"
    }
}

# Route Table
resource "aws_route_table" "this" {
    vpc_id = aws_vpc.this.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.this.id
    }

    tags = {
        Name = "${var.env}-${var.service_name}-rt"
    }
}

# Route Table Association
resource "aws_route_table_association" "publics" {
    for_each = aws_subnet.publics
    subnet_id = each.value.id
    route_table_id = aws_route_table.this.id
}