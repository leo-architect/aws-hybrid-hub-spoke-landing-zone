output "transit_gateway_id" {
  description = "ID do AWS Transit Gateway Central"
  value       = aws_ec2_transit_gateway.core_tgw.id
}

output "hub_vpc_id" {
  description = "ID da VPC Central (Shared Services & Centralized Egress)"
  value       = aws_vpc.hub.id
}

output "spoke_production_vpc_id" {
  description = "ID da VPC Spoke de Produção"
  value       = aws_vpc.spoke_prod.id
}

output "spoke_data_vpc_id" {
  description = "ID da VPC Spoke de Dados & Analytics"
  value       = aws_vpc.spoke_data.id
}
