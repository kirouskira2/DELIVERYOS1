# 🚀 Documento 5: Estratégia de Deploy e Infraestrutura
**Sistema:** Delivery OS (Motor Prisma V4.0)
**Fase:** 1 (Arquiteto)

## 1. Visão Geral da Infraestrutura
O Delivery OS (V4.0) foi desenhado para ser totalmente "Serverless/Edge", dispensando a necessidade de gerenciar servidores VPS complexos, orquestradores de contêineres ou clusters de banco de dados tradicionais. Esta arquitetura visa escalar automaticamente (do zero ao pico) e minimizar custos operacionais.

## 2. Componentes de Hospedagem

### 2.1. Frontend e Server Actions (Next.js) -> Vercel
A Vercel é a plataforma nativa para projetos Next.js.
- **Deploy Contínuo (CI/CD):** A Vercel conectará diretamente ao repositório GitHub (`main`). Qualquer commit na branch de produção disparará um build automático.
- **Vercel Edge Network:** Arquivos estáticos, CSS, Imagens e layouts cacheados serão distribuídos globalmente via CDN, reduzindo a latência para os restaurantes.
- **Serverless Functions:** As Server Actions (Lógica de autenticação, inserção de pedidos, cálculos) rodarão sob demanda em funções Serverless.

### 2.2. Banco de Dados e Autenticação -> Supabase
O Supabase atuará como o Backend-as-a-Service (BaaS).
- **PostgreSQL Database:** Banco de dados relacional poderoso, rodando com conexões seguras através de *Connection Pooling* nativo do Supabase (PgBouncer).
- **Supabase Auth:** Gerenciará tokens JWT, enviará e-mails de confirmação e lidará com os cookies de sessão, perfeitamente integrado ao Next.js SSR via pacote `@supabase/ssr`.
- **Database Functions & Triggers:** Lógica de baixa de estoque (`process_order_completion`) hospedada no próprio servidor Postgres para não onerar o tráfego de rede Serverless <-> Database.

## 3. Gestão de Variáveis de Ambiente (.env)
As variáveis de ambiente devem ser configuradas nos painéis da Vercel para garantir segurança.

**Supabase Variables:**
- `NEXT_PUBLIC_SUPABASE_URL`: Acessível pelo Client e Server.
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`: Chave anônima, segura para o frontend, limitada por RLS.
- `SUPABASE_SERVICE_ROLE_KEY`: **(SEGREDO MAXIMO)** Apenas para Server Actions (Factory 2) e integrações de sistema ou bypass de RLS quando absolutamente necessário. Nunca deve ser vazada para o client.

## 4. Estratégia de Atualização do Banco (Migrations)
- O Supabase CLI será utilizado em desenvolvimento local (`npx supabase start`).
- Mudanças no banco serão geradas na pasta `/supabase/migrations`.
- Durante o fluxo de Deploy, recomenda-se configurar o "Supabase GitHub Actions" para aplicar automaticamente as migrações no banco de produção ao aceitar PRs na `main`.

## 5. Auditoria de Segurança Pós-Deploy
Antes de autorizar o Go-Live, as seguintes checagens de infraestrutura devem ser aprovadas:
1. Nenhuma tabela possui o RLS desativado.
2. Nenhuma API key sensível (`SUPABASE_SERVICE_ROLE_KEY` ou chaves do `Stripe`/Gateway de pagamento) possuem o prefixo `NEXT_PUBLIC_`.
3. Todas as chamadas de banco de dados no Frontend dependem das validações do Supabase Auth no Server-Side.
