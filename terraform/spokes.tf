# Spoke 1: VPC de Produção (100% Privada, sem Internet Gateway)
resource "aws_vpc" "spoke_prod" {
  cidr_block           = var.spoke_prod_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-spoke-production-${var.environment}"
  }
}

resource "aws_subnet" "spoke_prod_private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.spoke_prod.id
  cidr_block        = cidrsubnet(var.spoke_prod_cidr, 4, count.index)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "sbn-spoke-prod-private-${var.availability_zones[count.index]}"
  }
}

resource "aws_route_table" "spoke_prod_rt" {
  vpc_id = aws_vpc.spoke_prod.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.core_tgw.id
  }

  tags = {
    Name = "rtb-spoke-prod-via-tgw"
  }
}

resource "aws_route_table_association" "spoke_prod_assoc" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.spoke_prod_private[count.index].id
  route_table_id = aws_route_table.spoke_prod_rt.id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_prod_attach" {
  subnet_ids                                      = aws_subnet.spoke_prod_private[*].id
  transit_gateway_id                              = aws_ec2_transit_gateway.core_tgw.id
  vpc_id                                          = aws_vpc.spoke_prod.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "attach-spoke-production"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke_prod_tgw_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_prod_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.rtb_spokes.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_prod_to_hub_rt" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_prod_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.rtb_hub.id
}

# Spoke 2: VPC de Dados & Analytics (100% Privada + S3 Gateway Endpoint FinOps)
resource "aws_vpc" "spoke_data" {
  cidr_block           = var.spoke_data_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-spoke-data-${var.environment}"
  }
}

resource "aws_subnet" "spoke_data_private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.spoke_data.id
  cidr_block        = cidrsubnet(var.spoke_data_cidr, 4, count.index)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "sbn-spoke-data-private-${var.availability_zones[count.index]}"
  }
}

resource "aws_route_table" "spoke_data_rt" {
  vpc_id = aws_vpc.spoke_data.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = aws_ec2_transit_gateway.core_tgw.id
  }

  tags = {
    Name = "rtb-spoke-data-via-tgw"
  }
}

resource "aws_route_table_association" "spoke_data_assoc" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.spoke_data_private[count.index].id
  route_table_id = aws_route_table.spoke_data_rt.id
}

# FinOps: S3 Gateway Endpoint gratuito para evitar tráfego S3 passando por NAT Gateway
resource "aws_vpc_endpoint" "spoke_data_s3" {
  vpc_id            = aws_vpc.spoke_data.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.spoke_data_rt.id]

  tags = {
    Name = "vpce-s3-gateway-spoke-data"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "spoke_data_attach" {
  subnet_ids                                      = aws_subnet.spoke_data_private[*].id
  transit_gateway_id                              = aws_ec2_transit_gateway.core_tgw.id
  vpc_id                                          = aws_vpc.spoke_data.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "attach-spoke-data"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "spoke_data_tgw_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_data_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.rtb_spokes.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_data_to_hub_rt" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.spoke_data_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.rtb_hub.id
}
