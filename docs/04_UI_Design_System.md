# 🎨 Documento 4: UI/UX e Design System (Factory 1)
**Sistema:** Delivery OS (Motor Prisma V4.0)
**Fase:** 1 (Arquiteto)

## 1. Princípios de Design Estético
O Delivery OS abandonará a aparência "sistêmica/bruta" tradicional e adotará uma estética **"Silicon Valley SaaS"**. O ambiente será voltado para a alta produtividade noturna ou ambientes com meia-luz, exigindo um Dark Mode sofisticado e de alto contraste.

- **Foco:** Performance visual, clareza tipográfica (sem serifa), e uso de micro-interações.
- **Glassmorphism:** Uso moderado de backgrounds translúcidos (blur) na barra lateral (Sidebar) e em Modais, transmitindo profundidade.

## 2. Design Tokens (Tailwind CSS)

### Cores Principais (Theming)
*   **Background (Global):** `bg-slate-950` (`#020617`) - Um tom noturno e profundo.
*   **Cards/Containers:** `bg-slate-900/80` (`#0f172a` com opacidade) + bordas sutis `border-slate-800`.
*   **Primary (Brand):** `bg-blue-600` (`#2563eb`) para botões de CTA principais ("Faturar Pedido", "Salvar").
*   **Success (KPIs Positivos):** `text-emerald-400` (`#34d399`) para receitas e aumentos de margem.
*   **Warning (Alertas de CMV):** `text-amber-500` (`#f59e0b`) para estoque baixo ou custo em ascensão.
*   **Danger (Cancelamentos):** `bg-red-500` para cancelamentos e exclusões críticas.

### Tipografia
*   **Fonte Base:** *Inter* (padrão Next.js) para máxima legibilidade de números no PDV e Dashboard.
*   **Títulos:** Pesos mais altos (SemiBold/Bold) em branco (`text-slate-50`).
*   **Texto Secundário:** Textos auxiliares e descrições em `text-slate-400`.

## 3. Componentes Base (shadcn/ui)
Para acelerar o desenvolvimento, a Factory 1 utilizará a biblioteca genérica *shadcn/ui*, estilizando-a para o tema definido.

- **Buttons:** Variantes customizadas (Default, Outline, Ghost, Destructive). Efeito visual de *glow* no `:hover` (sombra azulada leve).
- **Cards:** Usados para dashboards. Estrutura: `CardHeader` (Título e Ícone), `CardContent` (O dado/gráfico), `CardFooter` (Anotações).
- **Data Tables:** Construídas com `@tanstack/react-table`, contendo paginação nativa e filtros de busca responsivos.
- **Charts:** A biblioteca `recharts` embalada pelo `shadcn/ui (Charts)` para gráficos Lineares (Receita) e Barras (Volume de Pedidos).

## 4. Estrutura de Layout (App Shell)

### O "Dashboard Layout" (`/app/(dashboard)/layout.tsx`)
- **Sidebar (Esquerda):** Fixa, recolhível. Links: *Home (Dashboard), PDV, Cardápio, Estoque, Financeiro, Configurações*. Ícones via `lucide-react`.
- **Top Bar (Cabeçalho):** Relógio em tempo real, status do caixa (Aberto/Fechado), Notificações e Perfil do Usuário.
- **Main Content:** Área de rolagem para os *Server Components* injetarem a UI renderizada. Envelopada com animações suaves de transição (ex: `framer-motion` leve apenas em Client Components chave).

## 5. Micro-Interações e Loading States
- **Skeletons:** Ao invés de *spinners* clássicos, os Server Components utilizarão o `loading.tsx` do App Router para exibir `Skeleton` do shadcn, bloqueando apenas as áreas que estão sendo buscadas no banco.
- **Toasts:** Utilização do `sonner` para feedback instantâneo no rodapé direito ao concluir uma Server Action (ex: "✅ Pedido #102 Faturado com sucesso").
