# 🔌 Documento 3: Contratos de API e Server Actions
**Sistema:** Delivery OS (Motor Prisma V4.0)
**Fase:** 1 (Arquiteto)

## 1. Visão Geral da Arquitetura de Comunicação
De acordo com o Prisma V4.0, **não utilizaremos rotas de API padrão (`app/api/route.ts`)** para as operações internas do sistema. Em vez disso, a Factory 2 baseia-se puramente em **Next.js Server Actions** para operações de mutação (POST, PUT, DELETE) e Supabase SDK no servidor (Server Components) para consultas (GET). 

Isso garante "Type-Safety" ponta a ponta (Frontend -> Backend), sem a necessidade de parsing complexo de JSONs e fetch().

## 2. Padrão de Retorno (The "Action Response")
Todas as Server Actions exportadas retornarão a interface padrão para garantir consistência e fácil tratamento no cliente:
```typescript
type ActionResponse<T = any> = {
  success: boolean;
  data?: T;
  error?: string;
  statusCode: number;
}
```

## 3. Especificação das Server Actions (Factory 2)

### 3.1. `actions/auth.ts`
- **`login(formData: FormData): Promise<ActionResponse>`**
  - Autentica via e-mail e senha usando `supabase.auth.signInWithPassword`.
  - Retorna `success: true` e redireciona para `/dashboard`.
- **`logout(): Promise<ActionResponse>`**
  - Destrói a sessão SSR e limpa os cookies.

### 3.2. `actions/orders.ts` (Gestão de Pedidos)
- **`createOrder(payload: CreateOrderInput): Promise<ActionResponse<Order>>`**
  - Insere um registro na tabela `orders` e múltiplos registros em `order_items`.
  - *Transacionalidade garantida por RPC caso Next.js falhe em multi-inserts, ou múltiplas chamadas com rollback via código.*
- **`updateOrderStatus(orderId: string, status: OrderStatus): Promise<ActionResponse>`**
  - Se `status === 'completed'`, invoca a RPC nativa do banco `process_order_completion` (definida no Doc 2) para dar baixa automática nos insumos.

### 3.3. `actions/inventory.ts` (Estoque e Ficha Técnica)
- **`addInventoryItem(payload: InventoryInput): Promise<ActionResponse>`**
  - Cria um novo insumo.
- **`updateStock(itemId: string, quantity: number, type: 'add' | 'remove'): Promise<ActionResponse>`**
  - Ajusta o inventário manualmente (para recebimento de compras ou desperdício).

### 3.4. `actions/menu.ts` (Cardápio)
- **`createMenuItem(payload: MenuItemInput, recipe: RecipeInput[]): Promise<ActionResponse>`**
  - Cria o prato final e associa os insumos necessários (Ficha Técnica).

## 4. Consultas (Data Fetching / GET)
As leituras de dados serão feitas diretamente nos **Server Components** utilizando o Supabase Server Client. 
- Exemplo: O `Dashboard.tsx` irá invocar `const { data: metrics } = await supabase.rpc('get_dashboard_metrics')` ou executar queries nativas antes de renderizar a UI. Sem useEffect, sem loaders artificiais.
