# Defesa do Projeto: Alinhamento com a Trilha AWS Academy

Este documento serve como roteiro para explicar como a infraestrutura do **DeliveryOS** atende e supera os requisitos da Trilha de Laboratórios AWS Academy da CESAR School (https://dcpc-cesar-school.github.io/awsacademy26-1/).

Nós cumprimos os conceitos principais de todos os 3 módulos da trilha, adaptando as tecnologias para uma *stack* moderna (Dart, Flutter e Supabase) e superando limitações comuns de contas de estudantes (IAM restrito).

---

## Módulo 01: Fundação (Servidor e Banco de Dados)
> **Requisito Original:** EC2 (Ubuntu) → RDS PostgreSQL → API Node.js (com Security Groups).

**Como implementamos:**
- **Servidor:** Subimos uma instância EC2 t3.micro com Ubuntu 24.04.
- **Segurança:** Configuramos os Security Groups estritamente necessários (Portas 22 para SSH, 80 para HTTP e 443 para HTTPS).
- **Banco de Dados:** Em vez do AWS RDS, utilizamos o **Supabase**, que é essencialmente um PostgreSQL robusto rodando na nuvem como serviço (DBaaS). Isso demonstra domínio do conceito de banco de dados gerenciado.
- **API:** Em vez de Node.js, utilizamos **Dart Frog** compilado nativamente (*AOT*). Isso entregou uma performance absurdamente superior, consumindo uma fração da memória que o Node.js consumiria na mesma t3.micro.

---

## Módulo 02: Containers (Docker e Orquestração)
> **Requisito Original:** Docker Compose → Docker Hub → ECS.

**Como implementamos:**
- **Conteinerização Absoluta:** O projeto inteiro foi envelopado. Criamos um `Dockerfile` multi-stage avançado que gera uma imagem `debian-slim` minúscula para a API.
- **Orquestração Local (Docker Compose):** Criamos um `docker-compose.yml` que orquestra a API Dart e o Nginx na mesma rede Bridge isolada (`deliveryos-network`).
- **Por que não ECS?** Contas educacionais (Learner Labs) do AWS Academy costumam ter severas limitações de permissões no serviço IAM, o que frequentemente bloqueia o provisionamento de clusters no ECS. Optamos por rodar o Docker Compose diretamente na EC2 para garantir que o projeto funcionasse 100% sem esbarrar nos bloqueios burocráticos da conta de estudante, mas mantendo a **arquitetura de containers** exigida pelo módulo.

---

## Módulo 03: Escala e Acesso (ALB, Scaling e Segurança)
> **Requisito Original:** Load Balancer (ALB) → Auto Scaling → CloudWatch → IAM.

**Como implementamos:**
- **Load Balancing e Proxy Reverso:** Substituímos o Application Load Balancer (ALB) da AWS pelo **Nginx**, um dos proxies mais eficientes do mercado. Ele recebe todo o tráfego HTTP/HTTPS, serve o frontend (Flutter Web) e balanceia as requisições para a API isolada na porta 8080.
- **Segurança (Acesso HTTPS):** Fomos além do exigido e implementamos certificados SSL/TLS via Let's Encrypt com o domínio `sslip.io`, forçando HTTPS em todas as conexões, garantindo a criptografia dos dados em trânsito.
- **Escalabilidade Pronta:** A aplicação já está pronta para escalar (*Auto Scaling*). Como está conteinerizada e protegida por um proxy, para escalar o backend horizontalmente basta um único comando (`docker compose up --scale backend=N`), o que atende perfeitamente ao conceito teórico de "Scale Out" exigido na matéria.

---

## Conclusão para a Apresentação
O projeto não só atendeu aos fundamentos (IaaS, PaaS, Security Groups, Containers e Load Balancing) como resolveu o problema crítico de restrição de recursos da máquina (1GB de RAM) utilizando **Swap** no Linux e compilação em código de máquina (Dart AOT). A arquitetura final é profissional, segura (SSL) e independente de fornecedor (Cloud Agnostic).
