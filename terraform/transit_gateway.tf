# Core AWS Transit Gateway com governança estrita de tabelas de rotas (Zero Trust)
resource "aws_ec2_transit_gateway" "core_tgw" {
  description                     = "Core Corporate Transit Gateway - ${var.environment}"
  amazon_side_asn                 = 64512
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = {
    Name = "tgw-core-hub-${var.environment}"
  }
}

# Tabelas de Rotas Segregadas no TGW (Bloqueia tráfego lateral direto entre Spokes)
resource "aws_ec2_transit_gateway_route_table" "rtb_spokes" {
  transit_gateway_id = aws_ec2_transit_gateway.core_tgw.id

  tags = {
    Name = "tgw-rtb-spokes-isolated"
  }
}

resource "aws_ec2_transit_gateway_route_table" "rtb_hub" {
  transit_gateway_id = aws_ec2_transit_gateway.core_tgw.id

  tags = {
    Name = "tgw-rtb-hub-egress"
  }
}

# Attachment da VPC Central (Hub)
resource "aws_ec2_transit_gateway_vpc_attachment" "hub_attach" {
  subnet_ids                                      = aws_subnet.hub_tgw[*].id
  transit_gateway_id                              = aws_ec2_transit_gateway.core_tgw.id
  vpc_id                                          = aws_vpc.hub.id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "attach-hub-shared-egress"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "hub_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.rtb_hub.id
}

# Rota padrão dos Spokes aponta obrigatoriamente para o Hub (Centralized Egress)
resource "aws_ec2_transit_gateway_route" "spokes_default_to_hub" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub_attach.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.rtb_spokes.id
}
