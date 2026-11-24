# HLD / LLD — AWS Hybrid Hub-and-Spoke Network Landing Zone

## 1. High-Level Design (HLD)
### 1.1 Objetivo e Escopo
Fornecer a fundação de rede corporativa (*Network Landing Zone*) na AWS em modelo **Hub-and-Spoke**, garantindo segmentação de tráfego leste-oeste (Zero Trust), governança centralizada de saída para internet (*Centralized Egress*) e conectividade privada com serviços AWS (PrivateLink) e ambientes *on-premises*.

### 1.2 Pilares Arquiteturais (Well-Architected, Zero Trust & FinOps)
* **Zero Trust & Segmentação de Domínios:** Propagação e associação automática de rotas desativadas no Transit Gateway (`default_route_table_association = "disable"`). VPCs de aplicação (*Spokes*) não se comunicam diretamente entre si; todo tráfego passa por tabelas de rotas explícitas.
* **Otimização de Custos (FinOps):** Consolidação de **NAT Gateways** e **VPC Endpoints (S3 Gateway & Interface Endpoints)** exclusivamente na VPC Central (*Shared/Egress Hub*), evitando duplicação desses recursos em dezenas de contas/VPCs filhas.
* **Alta Disponibilidade:** Arquitetura Multi-AZ distribuída em duas zonas de disponibilidade (`sa-east-1a` e `sa-east-1b`) para sub-redes privadas, attachments do Transit Gateway e NAT Gateways.

---

## 2. Low-Level Design (LLD)
### 2.1 Plano de Endereçamento IP (IPAM / CIDR Allocation)
| Domínio / VPC | Bloco CIDR | Sub-redes | Função Arquitetural |
| :--- | :--- | :--- | :--- |
| **Hub Shared / Egress VPC** | `10.100.0.0/20` | Public Egress + TGW Attachments (2 AZs) | Saída centralizada para Internet (NAT GW) e hospedagem de VPC Endpoints compartilhados. |
| **Spoke Production VPC** | `10.101.0.0/20` | Private App + TGW Attachments (2 AZs) | Workloads produtivos isolados, sem Internet Gateway (IGW) direto. |
| **Spoke Data / Analytics VPC** | `10.102.0.0/20` | Private Data + TGW Attachments (2 AZs) | Camada de dados isolada da camada de aplicação. |

### 2.2 Matriz de Roteamento (Transit Gateway Route Tables)
* **Route Table `rtb-spokes`:** Associada às VPCs *Production* e *Data*. Possui apenas rota padrão (`0.0.0.0/0`) e rotas corporativas apontando para o attachment da **Hub Shared/Egress VPC** (impedindo tráfego lateral direto entre *Production* e *Data*).
* **Route Table `rtb-hub-egress`:** Associada à **Hub Shared/Egress VPC**. Possui rotas de retorno específicas para cada Spoke (`10.101.0.0/20`, `10.102.0.0/20`) e rota para o datacenter *on-premises*.
