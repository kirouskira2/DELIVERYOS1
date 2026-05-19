# 📄 Documento 1: Product Requirements Document (PRD)
**Sistema:** Delivery OS (Motor Prisma V4.0)
**Fase:** 1 (Arquiteto)

## 1. Visão Geral do Produto
O **Delivery OS** é um Sistema de Gestão para Restaurantes e Delivery, construído com foco absoluto em alta performance, UI/UX premium (estética de SaaS moderno do Vale do Silício) e Clean Architecture. A infraestrutura baseia-se no stack Prisma V4.0: Next.js (App Router), Tailwind CSS (shadcn/ui), e Supabase SSR.

## 2. Objetivos de Negócio (KPIs)
*   **Controle Absoluto (Dashboard e CMV):** Fornecer aos donos de restaurantes uma visão clara e em tempo real sobre Vendas, Custos e Margem de Lucro.
*   **Baixa de Estoque Automatizada:** Vincular a ficha técnica dos produtos do cardápio aos insumos do estoque para dar baixa automaticamente no momento do faturamento do pedido.
*   **Experiência Premium:** Interface "Dark Mode" elegante, rápida e responsiva para operação diária (Desktop e Mobile).

## 3. Público-Alvo e Atores (Roles)
*   **Admin/Gestor:** Tem acesso total ao Dashboard financeiro, relatórios de CMV, configurações de Fornecedores e gestão de Cardápio.
*   **Caixa/Operador:** Acessa o PDV, lança pedidos, finaliza transações e visualiza o fluxo de caixa do dia.
*   **Cozinha:** Visualiza apenas a fila de produção (KDS - Kitchen Display System), alterando o status dos pedidos para "Pronto".

## 4. Escopo Funcional (Épicos e Features)

### Épico 1: Autenticação e Segurança (Factory 2)
*   Login SSR seguro usando Supabase Auth.
*   Gestão de perfis e RLS (Row Level Security) para isolar permissões por usuário/unidade.

### Épico 2: Gestão de Pedidos (PDV)
*   Interface rápida para lançamento de pedidos (Mesa, Balcão, Delivery).
*   Fluxo de status do pedido (Novo -> Em Produção -> Pronto -> Finalizado/Faturado).
*   **Core Business Logic:** Ao mudar o status para "Faturado", o sistema dispara a Server Action que calcula e deduz do Estoque.

### Épico 3: Cardápio e Ficha Técnica
*   Cadastro de Categorias e Itens do Cardápio.
*   Associação N:N de Insumos (Ficha Técnica) com custo base.

### Épico 4: Gestão de Estoque e CMV
*   Entrada de Notas/Insumos (aumenta estoque).
*   Cálculo em tempo real do Custo da Mercadoria Vendida (CMV).

### Épico 5: Dashboard e Relatórios
*   Indicadores chaves: Receita Total, Ticket Médio, Custo de Estoque, Lucro Bruto e Margem.
*   Gráficos utilizando Recharts (integrado com shadcn/ui).

## 5. Requisitos Não Funcionais
*   **Design:** Dark Mode nativo, uso de Glassmorphism (blur translúcido), fontes modernas (Inter/Outfit) e transições suaves. Cores Brand: Blue Midnight (`#0f172a`), Azul Vibrante, Verde Esmeralda, Laranja e Vermelho Coral.
*   **Performance:** Páginas renderizadas no lado do servidor (SSR/RSC) sempre que possível para carga instantânea. Sem "Flashes" de carregamento.
*   **Segurança:** Acesso exclusivo ao banco de dados pelo Backend via Server Actions. Nenhuma chamada direta ao Supabase via Client Component.
