# ADR-001: Adoção de Topologia Hub-and-Spoke com AWS Transit Gateway vs. Malha Full-Mesh de VPC Peering

* **Status:** Aprovado
* **Contexto:** Crescimento do número de contas e VPCs produtivas, de dados e de serviços compartilhados em ambiente corporativo regulado, exigindo roteamento determinístico com o datacenter *on-premises* (Direct Connect / VPN) e controle centralizado de saída para a internet (*egress*).
* **Decisão:** Padronizar uma topologia **Hub-and-Spoke** baseada no **AWS Transit Gateway (TGW)** com tabelas de rotas segregadas por domínio de segurança (*Production*, *Shared/Egress* e *On-Premises*), eliminando comunicação lateral irrestrita entre VPCs (*Zero Trust Networking*).
* **Alternativas Avaliadas:**
  * *VPC Peering Full-Mesh:* Rejeitado pela não-transitividade das rotas (exigindo $N(N-1)/2$ conexões ponto a ponto), complexidade operacional crescente e impossibilidade de centralizar NAT Gateways e firewalls de borda.
  * *AWS Cloud WAN:* Avaliado para cenários multi-região globais; preterido neste blueprint regional pelo menor custo operacional e aderência direta ao modelo de Transit Gateway regional.
* **Consequências:**
  * **Positivas:** Isolamento estrito entre workloads (tráfego Spoke-to-Spoke bloqueado por padrão), redução de custos com NAT Gateways e Interface Endpoints centralizados na VPC de *Shared Services/Egress* (FinOps) e ponto único de terminação híbrida.
  * **Negativas / Trade-offs:** Custo adicional por hora de attachment no Transit Gateway e por GB processado, compensado pela consolidação dos ativos de borda e facilidade de auditoria.
