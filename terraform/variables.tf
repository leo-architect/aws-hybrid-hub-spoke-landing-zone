variable "aws_region" {
  description = "Região AWS da Landing Zone de Rede"
  type        = string
  default     = "sa-east-1"
}

variable "environment" {
  description = "Ambiente (shared, uat, prd)"
  type        = string
  default     = "prd"
}

variable "cost_center" {
  description = "Centro de custo de infraestrutura de rede (FinOps)"
  type        = string
  default     = "CC-CORE-NETWORK-01"
}

variable "availability_zones" {
  description = "Lista de Zonas de Disponibilidade para alta disponibilidade Multi-AZ"
  type        = list(string)
  default     = ["sa-east-1a", "sa-east-1b"]
}

variable "hub_vpc_cidr" {
  description = "Bloco CIDR da VPC Central (Shared Services & Centralized Egress)"
  type        = string
  default     = "10.100.0.0/20"
}

variable "spoke_prod_cidr" {
  description = "Bloco CIDR da VPC Spoke de Produção"
  type        = string
  default     = "10.101.0.0/20"
}

variable "spoke_data_cidr" {
  description = "Bloco CIDR da VPC Spoke de Dados & Analytics"
  type        = string
  default     = "10.102.0.0/20"
}

variable "onprem_cidr" {
  description = "Bloco CIDR summarizado do Datacenter On-Premises"
  type        = string
  default     = "172.16.0.0/12"
}

variable "enable_single_nat_gateway_finops" {
  description = "Guardrail FinOps: usa 1 NAT Gateway compartilhado em ambientes não-produtivos (false = 1 por AZ)"
  type        = bool
  default     = false
}
