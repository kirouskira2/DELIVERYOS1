# 🔍 Auditoria Técnica — Backend Dart | Delivery OS
**Data:** 2026-05-18 | **Auditor:** Antigravity AI | **Base de Verdade:** Prisma V4 + docs/

---

## Escopo Auditado

| Artefato | Caminho |
|---|---|
| Rotas (API Routes) | `routes/api/auth/`, `routes/api/pedidos/`, `routes/api/reports/` |
| Serviços | `lib/services/auth_service.dart`, `order_service.dart`, `dashboard_service.dart`, `inventory_service.dart` |
| Repositórios | `lib/repositories/order_repository.dart`, `report_repository.dart` |
| Modelos | `lib/models/pedido.dart` |
| DI & Config | `lib/di/setup.dart`, `routes/_middleware.dart`, `pubspec.yaml` |
| Testes | `test/routes/index_test.dart` |
| Documentação | `docs/01_PRD.md`, `docs/02_Data_Dictionary.md`, `docs/03_API_Contracts.md`, `Prisma/07_Audit_Framework_V4.md` |

---

## 1. Conformidade com a Documentação

### 1.1 Padrão de Resposta `ActionResponse`
> **Spec (docs/03_API_Contracts.md):**
> ```typescript
> type ActionResponse<T = any> = { success: boolean; data?: T; error?: string; statusCode: number }
> ```

✅ **Conforme** — `ActionResponse<T>` está corretamente implementado em `auth_service.dart` e usado por todos os serviços. A classe é genérica, tipada e contém todos os campos especificados.

```dart
// ✅ Implementação correta
class ActionResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;
```

---

### 1.2 Autenticação — Login e Logout
> **Spec:** `login(email, password)` → retorna sessão; `logout()` → destrói sessão.

✅ **Conforme** — `AuthService.login` usa `signInWithPassword` e retorna `Session` encapsulada. `AuthService.logout` usa `signOut`.

⚠️ **Divergência (Menor)** — A rota `POST /api/auth/logout` não valida o token de autorização do request antes de chamar `logout()`. Um usuário não autenticado pode invocar o endpoint sem erro.

**Sugestão de correção:**
```dart
// Em logout.dart — adicionar validação de header Authorization
final authHeader = context.request.headers['Authorization'];
if (authHeader == null || !authHeader.startsWith('Bearer ')) {
  return Response.json(statusCode: 401, body: {'success': false, 'error': 'Não autorizado.'});
}
```

---

### 1.3 Gestão de Pedidos
> **Spec (docs/03_API_Contracts.md):**
> - `createOrder(payload)` → insere pedido + itens
> - `updateOrderStatus(orderId, status)` → se `'concluido'`, dispara RPC de baixa de estoque

✅ **Conforme** — `OrderService.createOrder` e `updateOrderStatus` implementados corretamente. A lógica de disparar `processar_baixa_estoque_pedido` quando status é `'concluido'` está presente.

❌ **Crítico** — A rota `/api/pedidos/concluir` (único endpoint de pedidos) chama **diretamente** `OrderRepository.processarBaixaEstoquePedido`, contornando o `OrderService`. Isso quebra a separação de responsabilidades e duplica a rota de negócio.

**O fluxo correto seria:**
```
Flutter Client → PATCH /api/pedidos/{id}/status → OrderService.updateOrderStatus() → RPC Supabase
```

**O fluxo atual:**
```
Flutter Client → POST /api/pedidos/concluir → OrderRepository.processarBaixaEstoquePedido() (bypassa o Service)
```

**Correção — criar rota `routes/api/pedidos/[id]/status.dart`:**
```dart
// routes/api/pedidos/[id]/status.dart
import 'package:dart_frog/dart_frog.dart';
import 'package:backend_dart/di/setup.dart';
import 'package:backend_dart/services/order_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.patch) {
    return Response.json(statusCode: 405, body: {'success': false, 'error': 'Method Not Allowed'});
  }
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final novoStatus = body['status'] as String?;
    if (novoStatus == null || novoStatus.isEmpty) {
      return Response.json(statusCode: 400, body: {'success': false, 'error': 'O campo status é obrigatório.'});
    }
    final orderService = getIt<OrderService>();
    final result = await orderService.updateOrderStatus(pedidoId: id, novoStatus: novoStatus);
    return Response.json(
      statusCode: result.statusCode,
      body: result.success ? {'success': true} : {'success': false, 'error': result.error},
    );
  } catch (e) {
    return Response.json(statusCode: 500, body: {'success': false, 'error': 'Erro interno.'});
  }
}
```

---

### 1.4 Criação de Pedidos — Rota Ausente
> **Spec:** `createOrder(payload: CreateOrderInput): Promise<ActionResponse<Order>>`

❌ **Crítico** — **Não existe** a rota `POST /api/pedidos` (ou equivalente) que use `OrderService.createOrder`. O `OrderService` tem a lógica implementada, mas **nenhuma rota HTTP a expõe**. O Flutter precisaria chamar o Supabase diretamente para criar pedidos, violando o princípio de backend-first do Prisma V4.

**Correção — criar `routes/api/pedidos/index.dart`:**
```dart
import 'package:dart_frog/dart_frog.dart';
import 'package:backend_dart/di/setup.dart';
import 'package:backend_dart/services/order_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: 405, body: {'success': false, 'error': 'Method Not Allowed'});
  }
  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final clienteId = body['cliente_id'] as String?;
    final tipo = body['tipo'] as String? ?? 'balcao';
    final itens = (body['itens'] as List<dynamic>).cast<Map<String, dynamic>>();
    final observacoes = body['observacoes'] as String?;

    final orderService = getIt<OrderService>();
    final result = await orderService.createOrder(
      clienteId: clienteId,
      tipo: tipo,
      itens: itens,
      observacoes: observacoes,
    );
    return Response.json(
      statusCode: result.statusCode,
      body: result.success
          ? {'success': true, 'data': result.data}
          : {'success': false, 'error': result.error},
    );
  } catch (e) {
    return Response.json(statusCode: 500, body: {'success': false, 'error': 'Erro ao criar pedido.'});
  }
}
```

---

### 1.5 Gestão de Estoque — Rotas Ausentes
> **Spec (docs/03_API_Contracts.md):**
> - `addInventoryItem(payload)` → cria insumo
> - `updateStock(itemId, quantity, type)` → ajusta estoque manual

❌ **Crítico** — O `InventoryService` está implementado com ambas as funções, mas **nenhuma rota HTTP as expõe**. Não existe `routes/api/estoque/`. O Flutter chama o Supabase diretamente do client, violando a camada de backend.

---

### 1.6 Dashboard / KPIs
> **Spec (docs/03_API_Contracts.md):** Endpoint GET que retorna Receita, CMV, Ticket Médio, Lucro Bruto e Margem.

⚠️ **Divergência** — Existe **duplicidade** entre `ReportRepository.getDashboardMetrics()` (usado pela rota) e `DashboardService.getMetrics()` (implementação completa com CMV). A rota `GET /api/reports/dashboard` usa o `ReportRepository` que **não calcula CMV** — retorna apenas `receita_total`, `ticket_medio` e `quantidade_pedidos`. O `DashboardService` retorna todos os KPIs especificados (`cmv_total`, `lucro_bruto`, `margem_pct`, `total_despesas`), mas **nenhuma rota o usa**.

**Correção — a rota deve usar `DashboardService` e aceitar filtros de data:**
```dart
// routes/api/reports/dashboard.dart — versão corrigida
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(statusCode: 405, body: {'success': false, 'error': 'Method Not Allowed'});
  }
  try {
    final params = context.request.uri.queryParameters;
    final dataInicio = DateTime.tryParse(params['data_inicio'] ?? '') ?? 
        DateTime.now().subtract(const Duration(days: 30));
    final dataFim = DateTime.tryParse(params['data_fim'] ?? '') ?? DateTime.now();

    final dashboardService = getIt<DashboardService>();
    final result = await dashboardService.getMetrics(dataInicio: dataInicio, dataFim: dataFim);

    return Response.json(
      statusCode: result.statusCode,
      body: result.success
          ? {'success': true, 'data': result.data}
          : {'success': false, 'error': result.error},
    );
  } catch (e) {
    return Response.json(statusCode: 500, body: {'success': false, 'error': 'Erro ao carregar métricas.'});
  }
}
```

---

### 1.7 Cardápio / Menu — Completamente Ausente
> **Spec (docs/03_API_Contracts.md):**
> `createMenuItem(payload, recipe[])` → cria prato e associa ficha técnica

❌ **Crítico** — Não existe `MenuService`, `MenuRepository`, nem rota `routes/api/cardapio/`. O Flutter acessa `cardapio` e `ficha_tecnica` diretamente via Supabase client.

---

### 1.8 Clientes e Fornecedores — Ausentes no Backend
> **Spec (docs/01_PRD.md):** Gestão completa de clientes e fornecedores.

❌ **Crítico** — Não existem serviços, repositórios nem rotas para `clientes` ou `fornecedores`. O Flutter acessa essas tabelas diretamente via Supabase client, violando o isolamento de backend.

---

## 2. Lógica de Negócio

### 2.1 Baixa de Estoque Transacional
✅ **Conforme** — A lógica correta está em `OrderService.updateOrderStatus`: ao mudar para `'concluido'`, dispara `processar_baixa_estoque_pedido` (RPC Supabase com `SECURITY DEFINER`). Isso garante atomicidade transacional conforme especificado.

### 2.2 Cálculo de CMV
✅ **Conforme (no Service)** — `DashboardService.getMetrics` usa a RPC `calcular_cmv_periodo` e calcula `lucro_bruto` e `margem_pct` corretamente.

⚠️ **Divergência** — CMV não é exposto via rota (ver item 1.6).

### 2.3 Alertas de Estoque Mínimo
✅ **Conforme (no Service)** — `InventoryService.getLowStockAlerts` implementa a lógica.

❌ **Crítico** — Sem rota exposta, o alerta nunca chega ao frontend.

### 2.4 Multitenancy (Isolamento por `user_id`)
⚠️ **Divergência** — O isolamento existe no banco via RLS, mas o backend Dart não verifica `Authorization: Bearer <token>` antes de executar operações. Um token inválido passaria pelo middleware sem bloqueio, delegando toda a segurança ao Supabase.

**Sugestão — criar middleware de autenticação JWT:**
```dart
// lib/middleware/auth_middleware.dart
import 'package:dart_frog/dart_frog.dart';

Middleware authMiddleware() {
  return (handler) => (context) async {
    final authHeader = context.request.headers['Authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
        statusCode: 401,
        body: {'success': false, 'error': 'Token de autenticação ausente.'},
      );
    }
    // Passa o token para os handlers via context
    return handler(context);
  };
}
```

---

## 3. Qualidade do Código Dart

### 3.1 Convenções e Formatação
✅ **Conforme** — Código segue `lowerCamelCase` para métodos/variáveis e `UpperCamelCase` para classes. Imports organizados (dart: → package: → relative).

⚠️ **Divergência** — `order_repository.dart` contém `print()` (linha 17), proibido em produção pelo `dart analyze` (regra `avoid_print`).
```dart
// ❌ atual
print('Erro ao processar baixa de estoque: $e');

// ✅ correto — usar Logger ou rethrow
throw Exception('Erro ao processar baixa de estoque: $e');
```

### 3.2 Async/Await e Tratamento de Erros
✅ **Conforme** — Todos os métodos assíncronos usam `async/await` corretamente. `try/catch` presente em todas as camadas de serviço.

⚠️ **Divergência** — Em `inventory_service.dart`, a comparação de filtro de estoque mínimo usa `.filter('quantidade_atual', 'lte', 'quantidade_minima')` — isso passa a **string** `'quantidade_minima'` como valor literal, não como referência a coluna. Causará resultados incorretos.

```dart
// ❌ atual (compara com a string "quantidade_minima")
.filter('quantidade_atual', 'lte', 'quantidade_minima');

// ✅ correto — usar expressão SQL raw para comparar colunas
// A API Supabase Dart não suporta comparação entre colunas diretamente.
// Solução: criar uma RPC ou usar execute_sql com query nativa.
```

**Correção recomendada (nova RPC no banco):**
```sql
CREATE OR REPLACE FUNCTION get_low_stock_items()
RETURNS SETOF estoque AS $$
  SELECT * FROM public.estoque
  WHERE quantidade_atual <= quantidade_minima
    AND user_id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;
```
```dart
// ✅ em Dart
final response = await _supabase.rpc('get_low_stock_items');
```

### 3.3 Separação de Responsabilidades
⚠️ **Divergência** — `ReportRepository` mistura lógica de cálculo de métricas (acumulação de receita, ticket médio) com acesso a dados. Repositórios devem apenas retornar dados brutos; cálculos pertencem ao Service.

### 3.4 Tipagem e Type Safety
⚠️ **Divergência** — O modelo `Pedido` em `lib/models/pedido.dart` possui apenas 4 campos (`id`, `status`, `valorTotal`, `createdAt`), enquanto a tabela `pedidos` no banco contém: `user_id`, `cliente_id`, `tipo`, `observacoes`, `updated_at`. O modelo está incompleto para representar a entidade corretamente.

❌ **Crítico** — O cast `as Map<String, dynamic>` e `as List<dynamic>` nas rotas pode lançar `TypeError` não tratado se o payload chegou malformado. Falta validação de tipo com fallback.

```dart
// ❌ atual — lança exceção não tratada se body não for Map
final body = await context.request.json() as Map<String, dynamic>;

// ✅ correto — validar com fallback
final rawBody = await context.request.json();
if (rawBody is! Map<String, dynamic>) {
  return Response.json(statusCode: 400, body: {'success': false, 'error': 'Payload inválido.'});
}
final body = rawBody;
```

### 3.5 Credenciais Hard-coded
❌ **Crítico** — `lib/di/setup.dart` contém **credenciais reais hard-coded** como fallback:
```dart
// ❌ VIOLAÇÃO DE SEGURANÇA CRÍTICA
final supabaseUrl = Platform.environment['VITE_SUPABASE_URL'] ??
    'https://xnoivcxperibtuovusuo.supabase.co';      // ← URL real exposta
final supabaseKey = Platform.environment['VITE_SUPABASE_PUBLISHABLE_KEY'] ??
    'sb_publishable_MEY2Tu7dhx9LfkNjyiC5Gw_6jLXwprF'; // ← CHAVE REAL EXPOSTA
```
**Isso viola diretamente o `07_Audit_Framework_V4.md`, Seção 2 ("Proteção de Credenciais").**

**Correção:**
```dart
// ✅ correto — falhar ruidosamente se variável de ambiente ausente
final supabaseUrl = Platform.environment['SUPABASE_URL'] ??
    (throw StateError('SUPABASE_URL não configurada nas variáveis de ambiente.'));
final supabaseKey = Platform.environment['SUPABASE_PUBLISHABLE_KEY'] ??
    (throw StateError('SUPABASE_PUBLISHABLE_KEY não configurada nas variáveis de ambiente.'));
```

### 3.6 Nome das Variáveis de Ambiente
⚠️ **Divergência** — `setup.dart` lê `VITE_SUPABASE_URL` e `VITE_SUPABASE_PUBLISHABLE_KEY` (prefixo de Vite/frontend), mas o backend é Dart Frog e não tem Vite. O `.env.local` usa `NEXT_PUBLIC_SUPABASE_URL` (prefixo Next.js). Nenhum dos dois corresponde ao que o backend lê. As variáveis nunca serão encontradas em produção.

**Correção — padronizar para:**
```
SUPABASE_URL=https://xnoivcxperibtuovusuo.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

---

## 4. Cobertura e Consistência

### 4.1 Cobertura de Rotas vs. Especificação

| Endpoint Especificado | Status | Rota Dart Existente |
|---|---|---|
| `POST /api/auth/login` | ✅ Implementado | `routes/api/auth/login.dart` |
| `POST /api/auth/logout` | ✅ Implementado | `routes/api/auth/logout.dart` |
| `POST /api/pedidos` (criar) | ❌ Ausente | — |
| `PATCH /api/pedidos/{id}/status` | ❌ Ausente (existe só `concluir`) | `routes/api/pedidos/concluir.dart` |
| `POST /api/estoque` (addItem) | ❌ Ausente | — |
| `PATCH /api/estoque/{id}` (updateStock) | ❌ Ausente | — |
| `GET /api/estoque/alertas` | ❌ Ausente | — |
| `POST /api/cardapio` (createMenuItem) | ❌ Ausente | — |
| `GET /api/reports/dashboard` | ⚠️ Incompleto (sem CMV/filtros) | `routes/api/reports/dashboard.dart` |
| `GET /api/clientes` | ❌ Ausente | — |
| `POST /api/clientes` | ❌ Ausente | — |
| `GET /api/fornecedores` | ❌ Ausente | — |

### 4.2 Testes
❌ **Crítico** — Existe apenas 1 arquivo de teste (`index_test.dart`) que testa a rota raiz `/` (gerada pelo boilerplate do Dart Frog). **Nenhum serviço, repositório ou rota de negócio tem cobertura de teste**. O `pubspec.yaml` inclui `mocktail` e `test` como dev deps, sinalizando intenção nunca executada.

---

## 📊 Relatório Executivo

### Score por Categoria (0–10)

| Categoria | Score | Justificativa |
|---|---|---|
| **Conformidade com Documentação** | **3/10** | Apenas 2 de 11+ endpoints especificados estão completamente implementados |
| **Lógica de Negócio** | **6/10** | A lógica core (CMV, baixa de estoque) está correta nos services; o problema é na exposição via rotas |
| **Qualidade do Código Dart** | **5/10** | Boas práticas de async/await e separação de classes, mas há bug crítico de filtro de coluna e `print()` em produção |
| **Segurança** | **2/10** | Credenciais hard-coded no código-fonte, variáveis de ambiente erradas, ausência de middleware de autenticação |
| **Cobertura de Testes** | **1/10** | 1 teste de boilerplate, zero cobertura de negócio |
| **Score Médio Geral** | **3.4/10** | — |

---

### 🚨 Principais Riscos

1. **🔴 Credenciais expostas no código-fonte** (`setup.dart`) — chave publicável do Supabase em texto claro no repositório Git.
2. **🔴 Bug de filtro de estoque mínimo** — `getLowStockAlerts()` nunca retornará os dados corretos; compara número com string literal.
3. **🔴 Flutter acessa Supabase diretamente** em 7+ telas, contornando o backend Dart e anulando o valor arquitetural do Dart Frog.
4. **🟠 DashboardService implementado mas inacessível** — a rota usa `ReportRepository` que retorna apenas 3 KPIs em vez dos 7 especificados.
5. **🟡 Ausência total de testes** — qualquer refatoração é de alto risco sem cobertura.

---

### ✅ Plano de Ação Priorizado

#### 🔴 P0 — Segurança (Fazer Imediatamente)
1. **Remover credenciais hard-coded de `setup.dart`** e substituir por `throw StateError(...)` se variável ausente.
2. **Padronizar nomes de variáveis de ambiente** para `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY` no backend Dart, criando um `.env` próprio no diretório `backend_dart/`.
3. **Adicionar ao `.gitignore`** qualquer arquivo `.env` com valores reais.

#### 🔴 P1 — Bugs de Lógica (Corrigir Antes de Usar em Produção)
4. **Corrigir filtro de estoque mínimo** em `InventoryService.getLowStockAlerts()` → criar RPC `get_low_stock_items` no Supabase.
5. **Corrigir rota `/api/reports/dashboard`** para usar `DashboardService.getMetrics()` com filtros de data.

#### 🟠 P2 — Completar Cobertura de Rotas
6. **Criar `routes/api/pedidos/index.dart`** (POST criar pedido via `OrderService`).
7. **Criar `routes/api/pedidos/[id]/status.dart`** (PATCH status via `OrderService`).
8. **Criar `routes/api/estoque/index.dart`** e `routes/api/estoque/[id].dart` (via `InventoryService`).
9. **Criar `routes/api/cardapio/index.dart`** com novo `MenuService`.
10. **Adicionar middleware JWT** em `routes/_middleware.dart` para proteger rotas autenticadas.

#### 🟡 P3 — Qualidade e Manutenibilidade
11. **Remover `print()`** de `order_repository.dart` e substituir por `rethrow` ou logger.
12. **Completar modelo `Pedido`** com os campos faltantes (`tipo`, `clienteId`, `observacoes`, `userId`).
13. **Validar tipo de payload** nas rotas com guard `if (rawBody is! Map<String, dynamic>)`.
14. **Mover lógica de cálculo** de `ReportRepository` para `DashboardService` (SRP).

#### 🟢 P4 — Testes
15. **Criar testes unitários** para `AuthService`, `OrderService`, `DashboardService` e `InventoryService` usando `mocktail`.
16. **Criar testes de integração** para as rotas HTTP principais com `dart_frog_test`.
