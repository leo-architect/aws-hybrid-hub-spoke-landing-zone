# 1. VPC Central (Hub Shared & Centralized Egress)
resource "aws_vpc" "hub" {
  cidr_block           = var.hub_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-hub-shared-egress-${var.environment}"
  }
}

resource "aws_internet_gateway" "hub_igw" {
  vpc_id = aws_vpc.hub.id

  tags = {
    Name = "igw-hub-central-egress-${var.environment}"
  }
}

# Sub-redes Públicas (apenas para NAT Gateways centralizados)
resource "aws_subnet" "hub_public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = cidrsubnet(var.hub_vpc_cidr, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false # Zero Trust: impede IP público automático

  tags = {
    Name = "sbn-hub-public-egress-${var.availability_zones[count.index]}"
  }
}

# Sub-redes Privadas dedicadas aos Attachments do Transit Gateway
resource "aws_subnet" "hub_tgw" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.hub.id
  cidr_block        = cidrsubnet(var.hub_vpc_cidr, 4, count.index + 4)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "sbn-hub-tgw-attach-${var.availability_zones[count.index]}"
  }
}

# NAT Gateways Centralizados (FinOps: evita NAT GW duplicado em cada VPC Spoke)
locals {
  nat_gateway_count = var.enable_single_nat_gateway_finops ? 1 : length(var.availability_zones)
}

resource "aws_eip" "hub_nat_eip" {
  count  = local.nat_gateway_count
  domain = "vpc"

  tags = {
    Name = "eip-hub-nat-${count.index + 1}-${var.environment}"
  }
}

resource "aws_nat_gateway" "hub_nat" {
  count         = local.nat_gateway_count
  allocation_id = aws_eip.hub_nat_eip[count.index].id
  subnet_id     = aws_subnet.hub_public[count.index].id

  tags = {
    Name = "nat-hub-central-${count.index + 1}-${var.environment}"
  }

  depends_on = [aws_internet_gateway.hub_igw]
}

# Roteamento da VPC Hub
resource "aws_route_table" "hub_public_rt" {
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hub_igw.id
  }

  route {
    cidr_block         = var.spoke_prod_cidr
    transit_gateway_id = aws_ec2_transit_gateway.core_tgw.id
  }

  route {
    cidr_block         = var.spoke_data_cidr
    transit_gateway_id = aws_ec2_transit_gateway.core_tgw.id
  }

  tags = {
    Name = "rtb-hub-public-egress"
  }
}

resource "aws_route_table_association" "hub_public_assoc" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.hub_public[count.index].id
  route_table_id = aws_route_table.hub_public_rt.id
}

resource "aws_route_table" "hub_tgw_rt" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.hub.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.hub_nat[var.enable_single_nat_gateway_finops ? 0 : count.index].id
  }

  tags = {
    Name = "rtb-hub-tgw-to-nat-${var.availability_zones[count.index]}"
  }
}

resource "aws_route_table_association" "hub_tgw_assoc" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.hub_tgw[count.index].id
  route_table_id = aws_route_table.hub_tgw_rt[count.index].id
}
