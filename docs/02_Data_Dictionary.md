# 🗄️ Documento 2: Dicionário de Dados (Database Schema)
**Sistema:** Delivery OS (Motor Prisma V4.0)
**Fase:** 1 (Arquiteto)

## 1. Visão Arquitetural do Banco de Dados
O banco de dados será hospedado no **Supabase (PostgreSQL)**. A arquitetura utilizará `UUID` como chave primária para segurança e escalabilidade, e tabelas com `created_at` em `timestamptz`. Toda a proteção de acesso será governada por RLS (Row Level Security).

## 2. Tabelas Principais

### `users` (Gerenciado pelo Supabase Auth)
- Responsável pela autenticação. O Prisma V4.0 utiliza a tabela pública vinculada para perfis adicionais.

### `profiles` (Tabela Pública vinculada ao Auth)
- `id` (UUID, PK, FK para `auth.users.id`)
- `full_name` (Text)
- `role` (Enum: `admin`, `cashier`, `kitchen`)
- `created_at` (Timestamp)

### `categories` (Categorias do Cardápio)
- `id` (UUID, PK)
- `name` (Text, ex: "Bebidas", "Lanches")
- `created_at` (Timestamp)

### `menu_items` (Itens do Cardápio / Produtos Finais)
- `id` (UUID, PK)
- `category_id` (UUID, FK -> `categories.id`)
- `name` (Text)
- `description` (Text, nullable)
- `price` (Numeric 10,2)
- `created_at` (Timestamp)

### `inventory_items` (Insumos do Estoque)
- `id` (UUID, PK)
- `name` (Text)
- `unit` (Enum: `kg`, `litros`, `unidade`, `gramas`)
- `current_stock` (Numeric 10,3)
- `unit_cost` (Numeric 10,2) - Usado para calcular o custo (CMV)
- `created_at` (Timestamp)

### `recipes` (Ficha Técnica - Tabela Associativa)
- `id` (UUID, PK)
- `menu_item_id` (UUID, FK -> `menu_items.id`)
- `inventory_item_id` (UUID, FK -> `inventory_items.id`)
- `quantity_required` (Numeric 10,3) - Quanto do insumo é gasto por produto
- `created_at` (Timestamp)

### `orders` (Pedidos - PDV/Mesa/Delivery)
- `id` (UUID, PK)
- `customer_name` (Text, nullable)
- `type` (Enum: `table`, `counter`, `delivery`)
- `status` (Enum: `new`, `preparing`, `ready`, `completed`, `cancelled`)
- `total_amount` (Numeric 10,2)
- `payment_method` (Enum: `cash`, `credit_card`, `pix`)
- `created_at` (Timestamp)

### `order_items` (Itens dentro do Pedido)
- `id` (UUID, PK)
- `order_id` (UUID, FK -> `orders.id`)
- `menu_item_id` (UUID, FK -> `menu_items.id`)
- `quantity` (Integer)
- `unit_price` (Numeric 10,2)
- `created_at` (Timestamp)

## 3. Lógica de Negócios no Banco (Triggers & RPCs)
- **RPC `process_order_completion`:** Quando um pedido altera o `status` para `completed`, esta função será chamada para ler todos os `order_items`, buscar suas respectivas `recipes`, e subtrair a quantidade correta do `current_stock` na tabela `inventory_items`. Isso tira o peso do servidor Next.js e garante atomicidade transacional.

## 4. Políticas RLS (Row Level Security)
- **Admin:** Pode fazer `SELECT`, `INSERT`, `UPDATE`, `DELETE` em todas as tabelas.
- **Cashier:** Pode ler o cardápio e inserir/atualizar pedidos (`orders` e `order_items`).
- **Kitchen:** Pode apenas ler pedidos não finalizados e atualizar o status para `ready`. Nenhuma permissão de exclusão (DELETE).
