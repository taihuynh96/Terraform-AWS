# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = var.environment
    Environment = var.environment
  }
}

# Internet Gateway for Public Subnet
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

# Default Routing
resource "aws_default_route_table" "default_route_table" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id
  tags = {
    Name = "${var.environment}-Default-Route"
  }
}

///////////////////////////output define/////////////////////////////
# Subnets
# Elastic-IP (eip) for NAT
resource "aws_eip" "test-nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.ig]
}

# NAT
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.test-nat_eip.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)

  tags = {
    Name        = "${var.environment}-test-nat"
    Environment = "${var.environment}-test"
  }
}

# Public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.public_subnets_cidr)
  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-test-${element(var.availability_zones, count.index)}-public-subnet"
    Environment = "${var.environment}-test"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.private_subnets_cidr)
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.environment}-test-${element(var.availability_zones, count.index)}-private-subnet"
    Environment = "${var.environment}-test"
  }
}
# DB Subnet
resource "aws_subnet" "db_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.db_subnets_cidr)
  cidr_block              = element(var.db_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.environment}-test-${element(var.availability_zones, count.index)}-db-subnet"
    Environment = "${var.environment}-test"
  }
}


# Routing tables to route traffic for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.environment}-test-private-route-table"
    Environment = "${var.environment}-test"
  }
}


# Routing tables to route traffic for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.environment}-test-public-route-table"
    Environment = "${var.environment}-test"
  }
}

# Routing tables to route traffic for Public Subnet
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "${var.environment}-test-db-route-table"
    Environment = "${var.environment}-test"
  }
}

# Route for Internet Gateway
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

# Route for NAT
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}
/////////////////noi cac thanh phan voi nhau/////////////////////
# Route table associations for both Public & Private Subnets
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db" {
  count          = length(var.db_subnets_cidr)
  subnet_id      = element(aws_subnet.db_subnet.*.id, count.index)
  route_table_id = aws_route_table.db.id
}

///////////////////////////////////////////
////////VPC Endpoint////////////////////////////////

resource "aws_security_group" "sg-endpoint-service" {
  name        = "${var.environment}-endpoint-service-sg"
  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "TCP"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  vpc_id = aws_vpc.vpc.id
  tags = {
    Environment       = "${var.environment}-endpoint"
    Terraformed       = "true"
  }
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type   = "Gateway"
  route_table_ids     = [aws_route_table.private.id]
  policy              = jsonencode(
    {
      "Version": "2008-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": "*",
          "Action": "*",
          "Resource": "*"
        }
      ]
    }
  )
}

resource "aws_vpc_endpoint" "ecr-dkr-endpoint" {
  vpc_id              = aws_vpc.vpc.id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [element(aws_subnet.private_subnet.*.id, 0), element(aws_subnet.private_subnet.*.id, 1)]
  security_group_ids  = [aws_security_group.sg-endpoint-service.id]
}

resource "aws_vpc_endpoint" "ecr-api-endpoint" {
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true
  subnet_ids          = [element(aws_subnet.private_subnet.*.id, 0), element(aws_subnet.private_subnet.*.id, 1)]
  security_group_ids  = [aws_security_group.sg-endpoint-service.id]
}

resource "aws_vpc_endpoint" "ecs-agent" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ecs-agent"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [element(aws_subnet.private_subnet.*.id, 0), element(aws_subnet.private_subnet.*.id, 1)]
  security_group_ids  = [aws_security_group.sg-endpoint-service.id]
}
resource "aws_vpc_endpoint" "ecs-telemetry" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${var.region}.ecs-telemetry"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [element(aws_subnet.private_subnet.*.id, 0), element(aws_subnet.private_subnet.*.id, 1)]
  security_group_ids  = [aws_security_group.sg-endpoint-service.id]
}


